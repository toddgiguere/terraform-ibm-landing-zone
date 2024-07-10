##############################################################################
# QuickStart VSI Landing Zone
##############################################################################

locals {
  default_ocp_version = "${data.ibm_container_cluster_versions.cluster_versions.default_openshift_version}_openshift"
  ocp_version         = var.kube_version == null || var.kube_version == "default" ? local.default_ocp_version : "${var.kube_version}_openshift"
  entitlement_val     = var.entitlement == null ? "null" : "\"${var.entitlement}\""
}

data "ibm_container_cluster_versions" "cluster_versions" {
}

module "landing_zone" {
  source = "../.."
  prefix = var.prefix
  region = var.region
  tags   = var.resource_tags
  resource_groups = [{
    name       = var.existing_resource_group
    create     = false # created by stack before
    use_prefix = false
  }]
  cos = [{
    name           = "ocp"
    use_data       = false
    resource_group = var.existing_resource_group
    random_suffix  = true
    plan           = "standard"
    keys           = []
    buckets        = []
    }, {
    name           = var.existing_cos_instance_name
    use_data       = true # use existing instance
    resource_group = var.existing_resource_group
    plan           = "standard"
    keys           = []
    buckets = [{
      name          = "vpc-flow-bucket"
      storage_class = "standard"
      force_delete  = true
      endpoint_type = "public"
      kms_key       = "${var.prefix}-vpc-key"
    }]
  }]
  key_management = {
    name           = var.existing_key_management_name
    resource_group = var.existing_resource_group
    use_data       = true # reuse kms from stack
    keys = [{
      key_ring = "${var.prefix}-lz-ring"
      name     = "${var.prefix}-vpc-key"
      root_key = true
      policies = {
        rotation = {
          interval_month = 12
        }
      }
      },
      {
        key_ring = "${var.prefix}-lz-ring"
        name     = "${var.prefix}-ocp-key"
        root_key = true
        policies = {
          rotation = {
            interval_month = 12
          }
        }
    }]
  }
  vpcs = [{
    prefix                       = "workload"
    resource_group               = var.existing_resource_group
    clean_default_sg_acl         = true
    default_security_group_rules = []
    flow_logs_bucket_name        = "vpc-flow-bucket"
    network_acls = [
      {
        add_ibm_cloud_internal_rules = true
        add_vpc_connectivity_rules   = true
        name                         = "workload-acl"
        prepend_ibm_rules            = true
        rules                        = []
      }
    ]
    subnets = {
      zone-1 = [
        {
          acl_name       = "workload-acl"
          cidr           = "10.40.10.0/24"
          name           = "vsi-zone-1"
          public_gateway = true
        }
      ]
      zone-2 = [
        {
          acl_name       = "workload-acl"
          cidr           = "10.50.10.0/24"
          name           = "vsi-zone-2"
          public_gateway = true
        }
      ]
      zone-3 = [
        {
          acl_name       = "workload-acl"
          cidr           = "10.60.10.0/24"
          name           = "vsi-zone-3"
          public_gateway = true
        }
      ]
    }
    use_public_gateways = {
      zone-1 = true
      zone-2 = true
      zone-3 = true
    }
  }]
  clusters = [{
    addons                              = null
    boot_volume_crk_name                = "${var.prefix}-ocp-key"
    cluster_force_delete_storage        = false
    cos_name                            = "ocp"
    disable_outbound_traffic_protection = true
    entitlement                         = var.entitlement
    kms_config = {
      crk_name         = "${var.prefix}-ocp-key"
      private_endpoint = true
    }
    kms_wait_for_apply = true
    kube_type          = "openshift"
    kube_version       = var.kube_version
    machine_type       = var.flavor
    manage_all_addons  = false
    name               = "workload-cluster"
    resource_group     = var.existing_resource_group
    secondary_storage  = null
    subnet_names = [
      "vsi-zone-1",
      "vsi-zone-2",
      "vsi-zone-3",
    ]
    vpc_name           = "workload"
    worker_pools       = []
    workers_per_subnet = 1
  }]
  atracker = {
    add_route             = false # disable for stack
    receive_global_events = false
    collector_bucket_name = ""
    resource_group        = ""
  }
  vpn_gateways                           = []
  enable_transit_gateway                 = false
  transit_gateway_global                 = false
  transit_gateway_resource_group         = null
  transit_gateway_connections            = []
  virtual_private_endpoints              = []
  ssh_keys                               = []
  vsi                                    = []
  security_groups                        = []
  service_endpoints                      = "public-and-private"
  skip_all_s2s_auth_policies             = false
  skip_kms_block_storage_s2s_auth_policy = true

}

locals {
  override_string = <<EOF
{
   "atracker": {
      "collector_bucket_name": "",
      "receive_global_events": false,
      "resource_group": "",
      "add_route": false
   },
   "clusters": [
      {
         "boot_volume_crk_name": "slz-vsi-volume-key",
         "cos_name": "cos",
         "kube_type": "openshift",
         "kube_version": "${local.ocp_version}",
         "machine_type": "${var.flavor}",
         "name": "workload-cluster",
         "resource_group": "workload-rg",
         "disable_outbound_traffic_protection": true,
         "cluster_force_delete_storage": true,
         "kms_wait_for_apply": true,
         "kms_config": {
            "crk_name": "roks-key",
            "private_endpoint": true
         },
         "subnet_names": [
               "vsi-zone-1",
               "vsi-zone-2"
         ],
         "vpc_name": "workload",
         "worker_pools": [],
         "workers_per_subnet": 1,
         "entitlement": ${local.entitlement_val},
         "disable_public_endpoint": false
      }
   ],
   "cos": [
      {
         "access_tags": [],
         "buckets": [],
         "keys": [],
         "name": "cos",
         "plan": "standard",
         "random_suffix": true,
         "resource_group": "service-rg",
         "use_data": false
      }
   ],
   "enable_transit_gateway": true,
   "transit_gateway_global": false,
   "key_management": {
      "keys": [
         {
            "key_ring": "slz-ring",
            "name": "slz-vsi-volume-key",
            "root_key": true,
            "policies": {
               "rotation": {
                  "interval_month": 12
               }
            }
         },
         {
            "key_ring": "slz-ring",
            "name": "roks-key",
            "policies": {
               "rotation": {
                  "interval_month": 12
               }
            },
            "root_key": true
         }
      ],
      "name": "slz-kms",
      "resource_group": "service-rg",
      "use_hs_crypto": false,
      "use_data": false
   },
   "network_cidr": "10.0.0.0/8",
   "resource_groups": [
      {
         "create": true,
         "name": "service-rg",
         "use_prefix": true
      },
      {
         "create": true,
         "name": "management-rg",
         "use_prefix": true
      },
      {
         "create": true,
         "name": "workload-rg",
         "use_prefix": true
      }
   ],
   "security_groups": [],
   "transit_gateway_connections": [
      "management",
      "workload"
   ],
   "transit_gateway_resource_group": "service-rg",
   "virtual_private_endpoints": [],
   "vpcs": [
      {
         "default_security_group_rules": [],
         "clean_default_sg_acl": false,
         "flow_logs_bucket_name": null,
         "network_acls": [
            {
               "add_cluster_rules": false,
               "name": "management-acl",
               "rules": [
                  {
                     "name": "allow-ssh-inbound",
                     "action": "allow",
                     "direction": "inbound",
                     "tcp": {
                        "port_min": 22,
                        "port_max": 22
                     },
                     "source": "0.0.0.0/0",
                     "destination": "10.0.0.0/8"
                  },
                  {
                     "action": "allow",
                     "destination": "10.0.0.0/8",
                     "direction": "inbound",
                     "name": "allow-ibm-inbound",
                     "source": "161.26.0.0/16"
                  },
                  {
                     "action": "allow",
                     "destination": "10.0.0.0/8",
                     "direction": "inbound",
                     "name": "allow-all-network-inbound",
                     "source": "10.0.0.0/8"
                  },
                  {
                     "action": "allow",
                     "destination": "0.0.0.0/0",
                     "direction": "outbound",
                     "name": "allow-all-outbound",
                     "source": "0.0.0.0/0"
                  }
               ]
            }
         ],
         "prefix": "management",
         "resource_group": "management-rg",
         "subnets": {
            "zone-1": [
               {
                  "acl_name": "management-acl",
                  "cidr": "10.10.10.0/24",
                  "name": "vsi-zone-1",
                  "public_gateway": false
               }
            ],
            "zone-2": [],
            "zone-3": []
         },
         "use_public_gateways": {
            "zone-1": false,
            "zone-2": false,
            "zone-3": false
         },
         "address_prefixes": {
            "zone-1": [],
            "zone-2": [],
            "zone-3": []
         }
      },
      {
         "default_security_group_rules": [],
         "clean_default_sg_acl": false,
         "flow_logs_bucket_name": null,
         "network_acls": [
            {
               "add_cluster_rules": false,
               "name": "workload-acl",
               "rules": [
                  {
                     "action": "allow",
                     "destination": "0.0.0.0/0",
                     "direction": "inbound",
                     "name": "allow-all-network-inbound",
                     "source": "0.0.0.0/0"
                  },
                  {
                     "action": "allow",
                     "destination": "0.0.0.0/0",
                     "direction": "outbound",
                     "name": "allow-all-outbound",
                     "source": "0.0.0.0/0"
                  }
               ]
            }
         ],
         "prefix": "workload",
         "resource_group": "workload-rg",
         "subnets": {
            "zone-1": [
               {
                  "acl_name": "workload-acl",
                  "cidr": "10.40.10.0/24",
                  "name": "vsi-zone-1",
                  "public_gateway": true
               }
            ],
            "zone-2": [
               {
                  "acl_name": "workload-acl",
                  "cidr": "10.50.10.0/24",
                  "name": "vsi-zone-2",
                  "public_gateway": true
               }
            ],
            "zone-3": []
         },
         "use_public_gateways": {
            "zone-1": true,
            "zone-2": true,
            "zone-3": false
         },
         "address_prefixes": {
            "zone-1": [],
            "zone-2": [],
            "zone-3": []
         }
      }
   ],
   "vpn_gateways": []
}
EOF

}

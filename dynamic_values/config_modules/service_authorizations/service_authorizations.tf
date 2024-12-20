##############################################################################
# Variables
##############################################################################

variable "key_management" {
  description = "Direct reference to key management"
}

variable "key_management_guid" {
  description = "Key management guid"
}

variable "key_management_key_map" {
  description = "Key management key IDs"
}

variable "cos_instance_ids" {
  description = "Map of COS instance IDs"
}

variable "cos" {
  description = "COS variable"
}

variable "skip_kms_block_storage_s2s_auth_policy" {
  description = "Add kms to block storage s2s"
}

variable "skip_kms_kube_s2s_auth_policy" {
  description = "Add kms to kubernetes s2s"
}

variable "skip_all_s2s_auth_policies" {
  description = "Add s2s authorization policies"
}

variable "atracker_cos_bucket" {
  description = "Add atracker to cos s2s"
}

variable "clusters" {
  description = "Add cluster to kms auth policies"
}

variable "vsi" {
  description = "Add vsi block storage to auth policies"
}

##############################################################################

##############################################################################
# Locals
##############################################################################

locals {
  target_key_management_service = lookup(var.key_management, "name", null) != null ? lookup(var.key_management, "use_hs_crypto", false) == true ? "hs-crypto" : "kms" : null

  # create a list of keys used for all buckets, since we are going to scope the auth policy to keys.
  # doing this in a local first becase it needs a distinct to get rid of duplicates from same keys used
  # on multiple buckets, and a distinct on the final map may error in terraform for_each before first apply.
  cos_bucket_key_list_distinct = distinct(
    flatten([
      for instance in var.cos :
      [
        for bucket in instance.buckets :
        [
          {
            instance_name   = instance.name
            bucket_key_name = lookup(bucket, "kms_key", null)
          }
        ]
      ] if !instance.skip_kms_s2s_auth_policy
    ])
  )

  # get all keys that will be used for VSI block storage
  # this is combination of all boot volume keys, plus the extra storage volume keys
  block_storage_key_list_distinct = distinct(
    flatten([
      [
        for vsi in var.vsi :
        [
          { block_key_name = lookup(vsi, "boot_volume_encryption_key_name", null) }
        ]
      ],
      [
        for vsi in var.vsi :
        [
          for block in coalesce(lookup(vsi, "block_storage_volumes", null), []) :
          [
            { block_key_name = lookup(block, "encryption_key", null) }
          ]
        ]
      ]
    ])
  )

  # get all keys used in clusters
  # is combination of boot keys and config keys
  kube_key_list_distinct = distinct(
    flatten([
      [
        for cluster in var.clusters :
        [
          { cluster_key_name = lookup(cluster, "boot_volume_crk_name", null) }
        ]
      ],
      [
        for cluster in var.clusters :
        [
          { cluster_key_name = lookup(cluster.kms_config, "crk_name", null) }
        ] if lookup(cluster, "kms_config", null) != null
      ]
    ])
  )
}

module "kms_to_block_storage" {
  source = "../list_to_map"
  list = [
    for instance in local.block_storage_key_list_distinct :
    {
      name                        = "block-storage-to-${instance.block_key_name}"
      source_service_name         = "server-protect"
      description                 = "Allow block storage volumes to be encrypted by KMS key"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
      target_resource_type        = "key"
      target_resource_id          = split(":", var.key_management_key_map[instance.block_key_name].crn)[9]
      target_resource_account_id  = trimprefix(split(":", var.key_management_key_map[instance.block_key_name].crn)[6], "a/")
    } if local.target_key_management_service != null && !var.skip_kms_block_storage_s2s_auth_policy && instance.block_key_name != null
  ]
}

# Required service authorization access policy for Kubernetes Service and the KMS provider.
# This auth-policy only gets auto created if doing cluster data encryption.
# But for boot volume encryption, this policy needs to exist before cluster creation hence we need to explicitly create it.
module "kube_to_kms" {
  source = "../list_to_map"
  list = [
    for instance in local.kube_key_list_distinct :
    {
      name                        = "kube-to-${instance.cluster_key_name}"
      source_service_name         = "containers-kubernetes"
      description                 = "Allow cluster to be encrypted by KMS instance"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
      target_resource_type        = "key"
      target_resource_id          = split(":", var.key_management_key_map[instance.cluster_key_name].crn)[9]
      target_resource_account_id  = trimprefix(split(":", var.key_management_key_map[instance.cluster_key_name].crn)[6], "a/")
    } if local.target_key_management_service != null && !var.skip_kms_kube_s2s_auth_policy && instance.cluster_key_name != null
  ]
}

##############################################################################

##############################################################################
# COS to Key Management
##############################################################################

module "cos_to_key_management" {
  source = "../list_to_map"
  list = [
    for bucket_key in local.cos_bucket_key_list_distinct :
    {
      name                        = "cos-${bucket_key.instance_name}-to-key-${bucket_key.bucket_key_name}"
      source_service_name         = "cloud-object-storage"
      source_resource_instance_id = split(":", var.cos_instance_ids[bucket_key.instance_name])[7]
      description                 = "Allow COS instance to read KMS key"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
      target_resource_type        = "key"
      target_resource_id          = split(":", var.key_management_key_map[bucket_key.bucket_key_name].crn)[9]
      target_resource_account_id  = trimprefix(split(":", var.key_management_key_map[bucket_key.bucket_key_name].crn)[6], "a/")
    } if local.target_key_management_service != null && bucket_key.bucket_key_name != null
  ]
}

module "flow_logs_to_cos" {
  source = "../list_to_map"
  list = [
    for instance in var.cos :
    {
      name                        = "flow-logs-${instance.name}"
      source_service_name         = "is"
      source_resource_type        = "flow-log-collector"
      description                 = "Allow flow logs write access cloud object storage instance"
      roles                       = ["Writer"]
      target_service_name         = "cloud-object-storage"
      target_resource_instance_id = split(":", var.cos_instance_ids[instance.name])[7]
      target_resource_type        = null
      target_resource_id          = null
      target_resource_account_id  = null
    } if !instance.skip_flowlogs_s2s_auth_policy
  ]
}

##############################################################################

##############################################################################
# Atracker to COS
##############################################################################

locals {
  atracker_cos_instance = var.atracker_cos_bucket == null ? null : one(flatten([
    for instance in var.cos :
    [
      for bucket in instance.buckets :
      [instance.name] if bucket.name == var.atracker_cos_bucket
    ] if !instance.skip_atracker_s2s_auth_policy
  ]))
}

module "atracker_to_cos" {
  source = "../list_to_map"
  list = [
    for instance in(var.atracker_cos_bucket != null && local.atracker_cos_instance != null ? ["atracker-to-cos"] : []) :
    {
      name                        = instance
      source_service_name         = "atracker"
      description                 = "Allow atracker to write to COS"
      roles                       = ["Object Writer"]
      target_service_name         = "cloud-object-storage"
      target_resource_instance_id = split(":", var.cos_instance_ids[local.atracker_cos_instance])[7]
      target_resource_type        = null
      target_resource_id          = null
      target_resource_account_id  = null
    }
  ]
}

##############################################################################
# Outputs
##############################################################################

output "authorizations" {
  description = "Map of service authorizations"
  value = merge(
    module.kms_to_block_storage.value,
    module.cos_to_key_management.value,
    module.flow_logs_to_cos.value,
    module.atracker_to_cos.value,
    module.kube_to_kms.value
  )
}

##############################################################################

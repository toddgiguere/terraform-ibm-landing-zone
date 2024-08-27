##############################################################################
# Inputs
##############################################################################

variable "network_cidr" {
  description = "VPC network CIDR for rules destination"
  type        = string
}

##############################################################################
# Outputs
##############################################################################

output "bastion" {
  description = "Bastion allow all"
  value = [
    {
      name        = "allow-bastion-443-inbound"
      action      = "allow"
      direction   = "inbound"
      destination = var.network_cidr
      source      = "0.0.0.0/0"
      tcp = {
        source_port_min = 443
        source_port_max = 443
      }
    }
  ]
}

output "f5-external" {
  description = "F5 external allow all"
  value = [
    {
      name        = "allow-f5-external-443-inbound"
      action      = "allow"
      direction   = "inbound"
      destination = var.network_cidr
      source      = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    }
  ]
}

output "public_web_ingress" {
  description = "Public web traffic allow"
  value = [
    {
      name        = "allow-web-443-inbound"
      action      = "allow"
      direction   = "inbound"
      destination = var.network_cidr
      source      = "0.0.0.0/0"
      tcp = {
        source_port_min = 443
        source_port_max = 443
      }
    },
    {
      name        = "allow-web-80-inbound"
      action      = "allow"
      direction   = "inbound"
      destination = var.network_cidr
      source      = "0.0.0.0/0"
      tcp = {
        source_port_min = 80
        source_port_max = 80
      }
    }
  ]
}
##############################################################################

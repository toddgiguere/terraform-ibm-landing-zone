##############################################################################
# SSH Key Variables
##############################################################################

variable "ssh_keys" {
  description = "Direct reference to SSH keys"
}

##############################################################################

##############################################################################
# Account Variables
##############################################################################

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string


}

variable "resource_groups" {
  description = "Reference to compiled resource group locals"
}

##############################################################################

##############################################################################
# VPC Variables
##############################################################################

variable "vpc_modules" {
  description = "Direct reference to VPC Modules"
}

variable "vsi" {
  description = "Direct reference to VSI variable"
}

variable "bastion_vsi" {
  description = "Direct reference to Bastion VSI variable"
}

##############################################################################

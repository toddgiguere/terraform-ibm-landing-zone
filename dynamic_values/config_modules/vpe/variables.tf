##############################################################################
# VPE Variables
##############################################################################

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string


}

variable "region" {
  description = "VPC region"
}

variable "virtual_private_endpoints" {
  description = "Reference to virtual_private_endpoints variable"
}

variable "vpc_modules" {
  description = "map of vpc modules"
}

variable "cos_instance_ids" {
  description = "map of COS instance IDs"
}

##############################################################################

##############################################################################
# VPN Variables
##############################################################################

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string


}

variable "vpc_modules" {
  description = "map of vpc modules"
}

variable "vpn_gateways" {
  description = "List of vpn gateways"
}

##############################################################################

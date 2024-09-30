##############################################################################
# Variables
##############################################################################

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string


}

variable "f5_vsi" {
  description = "List of F5 vsi"
}

variable "vpc_modules" {
  description = "VPC modules"
}

variable "f5_template_data" {
  description = "Direct reference to template data"
}

variable "region" {
  description = "Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
}

##############################################################################

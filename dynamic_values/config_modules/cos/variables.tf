##############################################################################
# COS Variables
##############################################################################

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string


}

variable "suffix" {
  description = "Suffix for COS instance"
  type        = string
  default     = ""
}

variable "cos" {
  description = "Direct reference to cos variable"
}

variable "cos_data_source" {
  description = "COS Data Resources"
}

variable "cos_resource" {
  description = "Created COS instance resources"
}

variable "cos_resource_keys" {
  description = "Create COS resource keys"
}

##############################################################################

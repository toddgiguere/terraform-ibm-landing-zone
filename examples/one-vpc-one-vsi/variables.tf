##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "A unique identifier for resources that is prepended to resources that are provisioned. Must begin with a lowercase letter and end with a lowercase letter or number. Must be 16 or fewer characters."
  type        = string
  default     = "extra-simple"


}

variable "region" {
  description = "Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
  default     = "us-south"
}

variable "ssh_key" {
  description = "Public SSH Key for VSI creation. Must be a valid SSH key that does not already exist in the deployment region."
  type        = string
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

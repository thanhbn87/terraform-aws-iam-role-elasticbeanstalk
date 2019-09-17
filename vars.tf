#
# Variables
#
variable "namespace" { default = "" }
variable "name" { default = "role" }
variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-east-1" }
variable "temp_file_assumerole" { default = "" }
variable "temp_file_policy" { default = "" }
variable "iam_instance_profile" { default = "" }
variable "service_name" { default = "" }
variable "enhanced_reporting_enabled" { default = true }
variable "ssm_enabled" { default = true }
variable "ssm_registration_limit" { default = 1 }
variable "policy_resources" { default = ["*"] }

variable tags {
  default = {}
}

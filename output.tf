output "iam_instance_profile" {
  description = "The name of created iam_instance_profile"
  value       = "${var.iam_instance_profile == "" ? element(concat(aws_iam_instance_profile.ec2.*.name,list("")),0) : "" }"
}

output "service_name" {
  description = "The service role name of created service_name"
  value       = "${var.service_name == "" ? element(concat(aws_iam_role.service.*.name,list("")),0) : "" }"
}

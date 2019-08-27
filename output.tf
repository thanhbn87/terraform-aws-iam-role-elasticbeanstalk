output "iam_instance_profile" {
  description = "The name of created iam_instance_profile"
  value       = "${element(concat(aws_iam_instance_profile.ec2.*.name,list("")),0)}"
}

output "service_name" {
  description = "The service role name of created service_name"
  value       = "${element(concat(aws_iam_role.service.*.name,list("")),0)}"
}

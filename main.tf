provider "aws" {
  region  = "${var.aws_region}"
}

locals {
  common_tags = {
    Env       = "${var.project_env}"
    Namespace = "${var.namespace}"
  }
  temp_file_assumerole  = "${var.temp_file_assumerole == "" ? "../AssumeRoleService.json.tpl" : var.temp_file_assumerole }"
  temp_file_policy      = "${var.temp_file_policy == "" ? "../Policy.json.tpl" : var.temp_file_policy }"
  trust_identifiers     = [ "${split(",", var.ssm_enabled ? join(",",list("ec2.amazonaws.com","ssm.amazonaws.com")) : join(",", list("ec2.amazonaws.com")))}" ]
  iam_role_service_name = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(var.project_env_short)}-service-${lower(var.name)}"
  iam_role_ec2_name     = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(var.project_env_short)}-ec2-${lower(var.name)}"
}

#
# Service
#
data "template_file" "service" {
  count    = "${var.service_name == "" ? 1 : 0}"
  template = "${file(local.temp_file_assumerole)}"
  vars {
    identifiers = "${jsonencode(list("elasticbeanstalk.amazonaws.com"))}"
  }
}

resource "aws_iam_role" "service" {
  count              = "${var.service_name == "" ? 1 : 0 }"
  name               = "${local.iam_role_service_name}"
  assume_role_policy = "${data.template_file.service.rendered}"
  tags               = "${merge(var.tags, local.common_tags)}"
}

resource "aws_iam_role_policy_attachment" "enhanced-health" {
  count      = "${var.enhanced_reporting_enabled && var.service_name == "" ? 1 : 0}"
  role       = "${aws_iam_role.service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "service" {
  count      = "${var.service_name == "" ? 1 : 0 }"
  role       = "${aws_iam_role.service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

#
# EC2
#
data "template_file" "ec2" {
  count    = "${var.iam_instance_profile == "" ? 1 : 0}"
  template = "${file(local.temp_file_assumerole)}"
  vars {
    identifiers = "${jsonencode(local.trust_identifiers)}"
  }
}

data "template_file" "default" {
  count    = "${var.iam_instance_profile == "" ? 1 : 0}"
  template = "${file(local.temp_file_policy)}"
  //vars {
  //}
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_multi_container_docker" {
  count      = "${var.iam_instance_profile == "" ? 1 : 0}"
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role" "ec2" {
  count              = "${var.iam_instance_profile == "" ? 1 : 0}"
  name               = "${local.iam_role_ec2_name}"
  assume_role_policy = "${data.template_file.ec2.rendered}"
  tags               = "${merge(var.tags, local.common_tags)}"
}

resource "aws_iam_role_policy" "default" {
  count  = "${var.iam_instance_profile == "" ? 1 : 0}"
  name   = "${local.iam_role_ec2_name}"
  role   = "${aws_iam_role.ec2.id}"
  policy = "${data.template_file.default.rendered}"
}

resource "aws_iam_role_policy_attachment" "web-tier" {
  count      = "${var.iam_instance_profile == "" ? 1 : 0}"
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "worker-tier" {
  count      = "${var.iam_instance_profile == "" ? 1 : 0}"
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "ssm-ec2" {
  count      = "${var.iam_instance_profile == "" && var.ssm_enabled ? 1 : 0}"
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ssm-automation" {
  count      = "${var.iam_instance_profile == "" && var.ssm_enabled ? 1 : 0}"
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"

  lifecycle {
    create_before_destroy = true
  }
}

# http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker.container.console.html
# http://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html#AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "ecr-readonly" {
  count      = "${var.iam_instance_profile == "" ? 1 : 0}"
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_ssm_activation" "ec2" {
  count              = "${var.iam_instance_profile == "" && var.ssm_enabled ? 1 : 0}"
  name               = "${local.iam_role_ec2_name}"
  iam_role           = "${aws_iam_role.ec2.id}"
  registration_limit = "${var.ssm_registration_limit}"
}

resource "aws_iam_instance_profile" "ec2" {
  count = "${var.iam_instance_profile == "" ? 1 : 0}"
  name  = "${local.iam_role_ec2_name}"
  role  = "${aws_iam_role.ec2.name}"
}

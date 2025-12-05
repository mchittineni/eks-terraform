tflint {
  required_version = ">= 0.52.0"
}

config {
  format             = "compact"
  plugin_dir         = "~/.tflint.d/plugins"
  call_module_type   = "local"
  force              = false
  disabled_by_default = false

  # Ignore specific public modules
  ignore_module = {
    "terraform-aws-modules/vpc/aws"            = true
    "terraform-aws-modules/security-group/aws" = true
  }

  # Variable files and inline variables
  varfile = ["terraform.tfvars.example"]
}

# AWS Plugin with latest rules
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Terraform Plugin with strict rules
plugin "terraform" {
  enabled = true
  preset  = "all"
}

# Core rules - Ensure best practices
rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

# AWS Security Rules
rule "aws_instance_invalid_type" {
  enabled = false
}

rule "aws_kms_key_rotation_disabled" {
  enabled = true
}

rule "aws_security_group_rule_allows_all" {
  enabled = true
}

rule "aws_elb_missing_security_group" {
  enabled = true
}

rule "aws_instance_root_volume_encrypted" {
  enabled = true
}

rule "aws_db_instance_single_az" {
  enabled = true
}

rule "aws_dynamodb_point_in_time_recovery_disabled" {
  enabled = true
}

rule "aws_ebs_snapshot_copy_requires_encryption" {
  enabled = true
}
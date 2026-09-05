tflint {
  required_version = ">= 0.55.0"
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
  version = "0.38.0"
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

# AWS Rules
rule "aws_instance_invalid_type" {
  enabled = false
}

rule "aws_instance_previous_type" {
  enabled = true
}
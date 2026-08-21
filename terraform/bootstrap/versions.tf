terraform {
  # Provider bump is scoped to bootstrap only. Environment stacks remain on
  # hashicorp/aws ~> 5.40 until their Dependabot PRs are reviewed separately.
  # State encryption does NOT rely on provider defaults: bootstrap pins an
  # explicit CMK via kms_master_key_id on the state bucket SSE config.
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.57"
    }
  }
}

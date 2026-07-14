terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary provider - used for S3, Route 53
provider "aws" {
  region = var.aws_region
}

# CloudFront requires ACM certificates to be requested in us-east-1,
# regardless of which region the rest of the stack lives in. This must
# stay us-east-1 even though the primary provider above is us-west-2.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

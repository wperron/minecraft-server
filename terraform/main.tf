terraform {
  backend "s3" {
    region  = "ca-central-1"
    key     = "terraform.tfstate"
    encrypt = true
  }
}

resource "random_uuid" "this" {}

locals {
  suffix = substr(random_uuid.this.result, 0, 8)
  tags = {
    app       = var.app
    group     = var.group
    terraform = "true"
  }
}

data "aws_caller_identity" "this" {}

resource "aws_s3_bucket" "state" {
  bucket = "${var.app}-${var.group}-terraform-states-${local.suffix}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

resource "aws_dynamodb_table" "state" {
  name         = "${var.app}-${var.group}-terraform-lock-${local.suffix}"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}
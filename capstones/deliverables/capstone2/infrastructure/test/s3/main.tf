provider "aws" {
  region = "us-east-1"
}

module "s3_test" {
  source      = "../../modules/s3"
  environment = "test"
  buckets = {
    logs = {
      versioning_enabled     = true
      noncurrent_expiry_days = 30
    }
    assets = {
      versioning_enabled = false
    }
  }
}

output "bucket_names" {
  value = module.s3_test.bucket_names
}

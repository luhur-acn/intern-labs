output "bucket_names" {
  description = "Map of bucket IDs keyed by the same keys as the input map"
  value       = { for k, b in aws_s3_bucket.this : k => b.id }
}

output "bucket_arns" {
  description = "Map of bucket ARNs keyed by the same keys as the input map"
  value       = { for k, b in aws_s3_bucket.this : k => b.arn }
}

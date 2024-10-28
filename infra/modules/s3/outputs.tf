output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.project_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.project_bucket.arn
}
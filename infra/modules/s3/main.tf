resource "aws_s3_bucket" "project_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "project_bucket_versioning" {
  bucket = aws_s3_bucket.project_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
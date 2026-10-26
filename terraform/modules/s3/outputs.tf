output "bucket_id" {
  value       = aws_s3_bucket.main.id
  description = "The name/ID of the S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "The ARN of the S3 bucket"
}

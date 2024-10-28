# Output the python common layer ARN
output "python_common_layer_arn" {
  value = aws_lambda_layer_version.python_common_layer.arn
}

output "search_pubmed_summarize_lambda_function_name" {
  description = "The name of the search_pubmed_summarize Lambda function"
  value       = aws_lambda_function.search_pubmed_summarize.function_name
}

output "search_pubmed_summarize_lambda_function_arn" {
  description = "The ARN of the search_pubmed_summarize Lambda function"
  value       = aws_lambda_function.search_pubmed_summarize.arn
}

output "search_os_pubmed_lambda_function_name" {
  description = "The name of the search_os_pubmed Lambda function"
  value       = aws_lambda_function.search_os_pubmed.function_name
}

output "search_os_pubmed_lambda_function_arn" {
  description = "The ARN of the search_os_pubmed Lambda function"
  value       = aws_lambda_function.search_os_pubmed.arn
}

output "invoke_ingestion_lambda_function_name" {
  description = "The name of the invoke_ingestion Lambda function"
  value       = aws_lambda_function.invoke_ingestion.function_name
}

output "invoke_ingestion_lambda_function_arn" {
  description = "The ARN of the invoke_ingestion Lambda function"
  value       = aws_lambda_function.invoke_ingestion.arn
}

output "lambda_task_role_name" {
  description = "The name of the IAM role used by the Lambda functions"
  value       = aws_iam_role.lambda_task_role.name
}

output "lambda_task_role_arn" {
  description = "The ARN of the IAM role used by the Lambda functions"
  value       = aws_iam_role.lambda_task_role.arn
}

output "s3_deployment_bucket" {
  description = "The name of the S3 bucket used for Lambda deployment packages"
  value       = var.s3_deployment_bucket
}
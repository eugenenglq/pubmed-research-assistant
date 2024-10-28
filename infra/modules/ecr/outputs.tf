output "web_app_ecr_repository_url" {
  description = "The URL of the ECR repository for the web app"
  value       = aws_ecr_repository.web_app.repository_url
}

output "pubmed_ingest_data_ecr_repository_url" {
  description = "The URL of the ECR repository for the ingest data"
  value       = aws_ecr_repository.pubmed_ingest_data.repository_url
}

output "search_os_pubmed_lambda_repository_url" {
  description = "The URL of the ECR repository for the search os pubmed lambda function"
  value       = aws_ecr_repository.search_os_pubmed_lambda.repository_url
}

output "web_app_ecr_repository_url" {
  value = module.ecr.web_app_ecr_repository_url
}

output "pubmed_ingest_data_ecr_repository_url" {
  value = module.ecr.pubmed_ingest_data_ecr_repository_url
}

output "search_os_pubmed_lambda_repository_url" {
  value = module.ecr.search_os_pubmed_lambda_repository_url
}

output "web_app_ecr_repository_name" {
  value = module.ecr.web_app_ecr_repository_name
}

output "pubmed_ingest_data_ecr_repository_name" {
  value = module.ecr.pubmed_ingest_data_ecr_repository_name
}

output "search_os_pubmed_lambda_repository_name" {
  value = module.ecr.search_os_pubmed_lambda_repository_name
}
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "pubmed_index_name" {
  description = "OpenSearch index name"
  type        = string
  default     = "pubmed-abstract"
}

variable "private_subnet_ids" {
  description = "List of IDs of private subnets"
  type        = list(string)
}

variable "web_app_target_group_arn" {
  description = "The ARN of the Target Group for the web application"
  type        = string
}

variable "ecs_security_group_id" {
  description = "The ID of the security group for the ECS service"
  type        = string
}

variable "search_term_dynamodb_table_name" {
  description = "Dynamodb table name for search term"
  type        = string
}

variable "web_app_ecr_repository_url" {
  description = "The URL of the ECR repository for the web app"
  type        = string
}

variable "pubmed_ingest_data_ecr_repository_url" {
  description = "The URL of the ECR repository for the ingest data"
  type        = string
}

variable "search_os_pubmed_lambda_repository_url" {
  description = "The URL of the ECR repository for the search os pubmed lambda function"
  type        = string
}

variable "sample_prompts_dynamodb_table_name" {
  description = "DynamoDB table name for sample prompts"
  type        = string
}

variable "bedrock_agent_id" {
  description = "Bedrock agent ID"
  type        = string
}

variable "bedrock_agent_alias_id" {
  description = "Bedrock agent alias ID"
  type        = string
}
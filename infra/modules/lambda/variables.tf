variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "s3_deployment_bucket" {
  description = "Name of the S3 bucket to be accessed by Lambda"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
}

variable "pubmed_ingest_data_task_definition_arn" {
  description = "The ARN of the ingest data task definition"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of IDs of private subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The ID of the security group for the ECS service"
  type        = string
}

variable "search_os_pubmed_lambda_repository_name" {
  description = "The ECR repo name for search_os_pubmed_lambda"
  type        = string
}

variable "search_os_pubmed_lambda_repository_url" {
  description = "The ECR repo url for search_os_pubmed_lambda"
  type        = string
}
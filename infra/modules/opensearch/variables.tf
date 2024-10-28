variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_opensearchserverless_vpc_endpoint" {
  description = "OpenSearch VPC Endpoint"
  type        = string
}

variable "opensearch_granted_iam_role_arns" {
  description = "List of IAM role ARNs that can access OpenSearch"
  type        = list(string)
}
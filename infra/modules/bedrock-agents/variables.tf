variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "model_id" {
  description = "Default model ID for Bedrock agent"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "search_pubmed_summarize_lambda_function_arn" {
  description = "The ARN of the search_pubmed_summarize Lambda function"
  type        = string
}

variable "search_os_pubmed_lambda_function_arn" {
  description = "The ARN of the search_os_pubmed Lambda function"
  type        = string
}

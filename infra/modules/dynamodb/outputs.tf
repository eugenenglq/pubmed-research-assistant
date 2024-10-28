output "search_term_dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.pubmed_search_term.name
}

output "sample_prompts_dynamodb_table_name" {
  description = "The name of the DynamoDB table for sample prompts"
  value       = aws_dynamodb_table.web_sample_prompts.name
}
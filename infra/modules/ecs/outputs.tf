output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "web_app_task_definition_arn" {
  description = "The ARN of the web app task definition"
  value       = aws_ecs_task_definition.web_app.arn
}

output "pubmed_ingest_data_task_definition_arn" {
  description = "The ARN of the ingest data task definition"
  value       = aws_ecs_task_definition.pubmed_ingest_data.arn
}

output "web_app_service_name" {
  description = "The name of the web app ECS service"
  value       = aws_ecs_service.web_app.name
}

output "web_app_cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for the web app"
  value       = aws_cloudwatch_log_group.web_app.name
}

output "pubmed_ingest_data_cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for the ingest data"
  value       = aws_cloudwatch_log_group.pubmed_ingest_data.name
}

output "web_app_task_role_arn" {
  description = "The ARN of the web app task role"
  value       = aws_iam_role.web_app_task_role.arn
}

output "ecs_execution_role_arn" {
  description = "The ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ingest_task_role_arn" {
  description = "The ARN of the ingest task role"
  value       = aws_iam_role.ingest_task_role.arn
}

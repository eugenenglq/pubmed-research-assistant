output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.web_app.dns_name
}

output "web_app_target_group_arn" {
  description = "The ARN of the Target Group for the web application"
  value       = aws_lb_target_group.web_app.arn
}

output "ecs_security_group_id" {
  description = "The ID of the security group for the ECS service"
  value       = aws_security_group.ecs.id
}

output "aws_opensearchserverless_vpc_endpoint" {
  description = "The ID of the VPC endpoint for OpenSearch Serverless"
  value       = aws_opensearchserverless_vpc_endpoint.private_endpoint.id
}

output "aws_opensearchserverless_security_group_id" {
  description = "The ID of the security group for the OpenSearch service"
  value       = aws_security_group.ecs.id
}
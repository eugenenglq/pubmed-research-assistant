provider "aws" {
  region = var.aws_region
}

module "networking" {
  project_name = var.project_name
  source             = "./modules/networking"
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "s3" {
  project_name = var.project_name
  source      = "./modules/s3"
  bucket_name = "${var.project_name}-bucket"
}

module "ecr" {
  project_name = var.project_name
  source      = "./modules/ecr"
}

module "ecs" {
  project_name = var.project_name
  source       = "./modules/ecs"
  private_subnet_ids   = module.networking.private_subnet_ids
  web_app_target_group_arn = module.networking.web_app_target_group_arn
  ecs_security_group_id = module.networking.ecs_security_group_id
  search_term_dynamodb_table_name = module.dynamodb.search_term_dynamodb_table_name
  web_app_ecr_repository_url = module.ecr.web_app_ecr_repository_url
  pubmed_ingest_data_ecr_repository_url = module.ecr.pubmed_ingest_data_ecr_repository_url
  search_os_pubmed_lambda_repository_url = module.ecr.search_os_pubmed_lambda_repository_url
  sample_prompts_dynamodb_table_name = module.dynamodb.sample_prompts_dynamodb_table_name
  bedrock_agent_id = module.bedrock_agents.agent_id
  bedrock_agent_alias_id = module.bedrock_agents.agent_alias_id
}


module "lambda" {
  project_name = var.project_name
  source       = "./modules/lambda"
  s3_deployment_bucket     = module.s3.bucket_name
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  pubmed_ingest_data_task_definition_arn = module.ecs.pubmed_ingest_data_task_definition_arn
  ecs_security_group_id = module.networking.ecs_security_group_id
  private_subnet_ids = module.networking.private_subnet_ids
  search_os_pubmed_lambda_repository_url = module.ecr.search_os_pubmed_lambda_repository_url
}

module "dynamodb" {
  project_name = var.project_name
  source       = "./modules/dynamodb"
  invoke_ingestion_lambda_function_arn = module.lambda.invoke_ingestion_lambda_function_arn
}

module "opensearch" {
  project_name = var.project_name
  source         = "./modules/opensearch"
  aws_opensearchserverless_vpc_endpoint = module.networking.aws_opensearchserverless_vpc_endpoint
  opensearch_granted_iam_role_arns = [
    module.lambda.lambda_task_role_arn, module.ecs.ingest_task_role_arn
  ]
}

module "bedrock_agents" {
  project_name = var.project_name
  source         = "./modules/bedrock-agents"
  search_pubmed_summarize_lambda_function_arn = module.lambda.search_pubmed_summarize_lambda_function_arn
  search_os_pubmed_lambda_function_arn = module.lambda.search_os_pubmed_lambda_function_arn
}

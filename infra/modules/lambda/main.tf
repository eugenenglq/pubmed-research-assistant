data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# LAMBDA LAYERS

# Create a zip file from the layer contents
data "archive_file" "python_common_layer_zip" {
  type        = "zip"
  source_dir  = "../lambda-layers/python-common"  # Replace with the path to your layer contents
  output_path = "../bin/lambda-layers/python-common.zip"
}

# Create the Lambda layer
resource "aws_lambda_layer_version" "python_common_layer" {
  filename            = data.archive_file.python_common_layer_zip.output_path
  source_code_hash    = data.archive_file.python_common_layer_zip.output_base64sha256
  layer_name          = "${var.project_name}-python-common" 
  compatible_runtimes = ["python3.9"]
  description         = "Common Python 3.9 layer"
}


data "aws_ecr_image" "search_os_pubmed_lambda_repository_image" {
  repository_name = var.search_os_pubmed_lambda_repository_name
  image_tag       = "latest"
}

resource "aws_lambda_function" "search_os_pubmed" {
  function_name    = "${var.project_name}-search-os-pubmed"
  role             = aws_iam_role.lambda_task_role.arn
  package_type  = "Image"
  image_uri     = "${var.search_os_pubmed_lambda_repository_url}:latest"
  timeout       = 600
  environment {
    variables = {
      BEDROCK_EMBEDDING_MODEL_ID = "amazon.titan-embed-text-v2:0"
      BEDROCK_MODEL_ID           = "anthropic.claude-3-sonnet-20240229-v1:0"
      COLLECTION_NAME                 = "${var.project_name}-pubmed-collection"
      INDEX_NAME                 = "pubmed-abstract"
    }
  }
  source_code_hash = trimprefix(data.aws_ecr_image.search_os_pubmed_lambda_repository_image.id, "sha256:")

  tags = {
    Name        = "${var.project_name}-search-os-pubmed"
    Project     = var.project_name
    # Environment = var.environment
  }
}

resource "aws_lambda_permission" "search_os_pubmed_allow_bedrock" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.search_os_pubmed.function_name
  principal     = "bedrock.amazonaws.com"
  
  # Optional: Add source ARN condition
  source_arn    = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
}

# LAMBDA FUNCTION: invoke-ingestion

data "archive_file" "invoke_ingestion" {
  type        = "zip"
  source_dir  = "../lambda-functions/invoke-ingestion"
  output_path = "../bin/lambda-functions/invoke-ingestion.zip"
}

resource "aws_lambda_function" "invoke_ingestion" {
  filename            = data.archive_file.invoke_ingestion.output_path
  source_code_hash    = data.archive_file.invoke_ingestion.output_base64sha256
  function_name    = "${var.project_name}-invoke-ingestion"
  role             = aws_iam_role.lambda_task_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  environment {
    variables = {
      CLUSTER_ARN             = var.ecs_cluster_arn
      TASK_DEFINITION_ARN     = var.pubmed_ingest_data_task_definition_arn
      SUBNET_ID               = var.private_subnet_ids[0]
      SECURITY_GROUP_ID       = var.ecs_security_group_id
    }
  }
}

resource "aws_lambda_permission" "invoke_ingestion_permission" {
  statement_id  = "AllowDynamoDBToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.invoke_ingestion.function_name
  principal     = "dynamodb.amazonaws.com"
}

data "archive_file" "search_pubmed_summarize" {
  type        = "zip"
  source_dir  = "../lambda-functions/search-pubmed-summarize"
  output_path = "../bin/lambda-functions/search-pubmed-summarize.zip"
}

resource "aws_lambda_function" "search_pubmed_summarize" {
  filename            = data.archive_file.search_pubmed_summarize.output_path
  source_code_hash    = data.archive_file.search_pubmed_summarize.output_base64sha256
  function_name    = "${var.project_name}-search-pubmed-summarize"
  role             = aws_iam_role.lambda_task_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.python_common_layer.arn]
  timeout          = 600
  environment {
    variables = {
      MODEL_ID     = "anthropic.claude-3-sonnet-20240229-v1:0"
    }
  }
}

resource "aws_lambda_permission" "search_pubmed_summarize_allow_bedrock" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.search_pubmed_summarize.function_name
  principal     = "bedrock.amazonaws.com"
  
  # Optional: Add source ARN condition
  source_arn    = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
}

# IAM ROLES
resource "aws_iam_role" "lambda_task_role" {
  name = "${var.project_name}-lambda-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "lambda_task_role" {
  role_name       = aws_iam_role.lambda_task_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess",
    "arn:aws:iam::aws:policy/AmazonBedrockFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  ]
}


resource "aws_iam_role_policy" "lambda_task_role_aoss_access" {
  name = "AOSSAccess"
  role = aws_iam_role.lambda_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:*"
        ]
        Resource = "*"
      }
    ]
  })
}
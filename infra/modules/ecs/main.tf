provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Project = var.project_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "web_app" {
  family                   = "${var.project_name}--web-app"
  task_role_arn            = aws_iam_role.web_app_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name  = "web-app"
      image = "${var.web_app_ecr_repository_url}:latest"
      portMappings = [
        {
          name          = "8501"
          containerPort = 8501
          hostPort      = 8501
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web_app.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      cpu    = 256
      memory = 512
      environment = [
        {
          name  = "REGION"
          value = "us-east-1"
        },
        {
          name  = "SAMPLE_PROMPTS_DD"
          value = var.sample_prompts_dynamodb_table_name
        },
        {
          name  = "BEDROCK_AGENT_ID"
          value = var.bedrock_agent_id
        },
        {
          name  = "BEDROCK_AGENT_ALIAS_ID"
          value = var.bedrock_agent_alias_id
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "web_app" {
  name            = "${var.project_name}-web-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_app.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = var.web_app_target_group_arn
    container_name   = "web-app"
    container_port   = 8501
  }

  tags = {
    Project = "pubmed-assistant"
  }
}

resource "aws_ecs_task_definition" "pubmed_ingest_data" {
  family                   = "${var.project_name}-pubmed-ingest-data"
  task_role_arn            = aws_iam_role.ingest_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name   = "ingest"
      image  = "${var.pubmed_ingest_data_ecr_repository_url}:latest"
      cpu    = 256
      memory = 512
      environment = [
        {
          name  = "REGION"
          value = "us-east-1"
        },
        {
          name  = "COLLECTION_NAME"
          value = "${var.project_name}-pubmed-collection"
        },
        {
          name  = "INDEX_NAME"
          value = var.pubmed_index_name
        },
        {
          name  = "EMBEDDING_MODEL"
          value = "amazon.titan-embed-text-v2:0"
        },
        {
          name  = "SEARCH_TERM_DD"
          value = var.search_term_dynamodb_table_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.pubmed_ingest_data.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "web_app" {
  name = "/ecs/${var.project_name}-web-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "pubmed_ingest_data" {
  name = "/ecs/${var.project_name}-pubmed-ingest-data"
  retention_in_days = 30
}


# IAM ROLES
resource "aws_iam_role" "web_app_task_role" {
  name = "${var.project_name}-web-app-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${var.project_name}-dynamodb-access"
  role = aws_iam_role.web_app_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.project_name}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "web_app_task_role" {
  role_name       = aws_iam_role.web_app_task_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess",
    "arn:aws:iam::aws:policy/AmazonBedrockFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  ]
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachments_exclusive" "ecs_execution_role" {
  role_name       = aws_iam_role.ecs_execution_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_role_policy" "ecs_execution_role_ecr_access" {
  name = "ECRAccess"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_execution_role_cloudwatch_logs_access" {
  name = "CloudWatchLogsAccess"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ingest_task_role" {
  name = "${var.project_name}-ingest-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "ingest_task_role" {
  role_name       = aws_iam_role.ingest_task_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess",
    "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  ]
}

resource "aws_iam_role_policy" "ingest_task_role_aoss_access" {
  name = "AOSSAccess"
  role = aws_iam_role.ingest_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.project_name}*" 
      }
    ]
  })
}
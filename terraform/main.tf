# Define locals for ECR repository URLs
# Fetch the current AWS account ID
data "aws_caller_identity" "current" {}

# Fetch the current AWS region
data "aws_region" "current" {}

# Data source for availability zones
data "aws_availability_zones" "available" {}

locals {
  ecr_repository_url_backend = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/plantstore-backend-registry"
}

# ----------------------------------------------------------------------------------------------------------------------
# credentials are fetched from credential file
# provider configurations
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # deployment region region
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Roles
# ---------------------------------------------------------------------------------------------------------------------

# IAM Role for CodePipeline for AWS to access github
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role" # role  name

  # allow codepipeline service to assume the role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# attaches the AWSCodePipelineFullAccess policy to the role, granting it the necessary permissions
resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
  role       = aws_iam_role.codepipeline_role.name
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policies for CodeBuild Role
# ---------------------------------------------------------------------------------------------------------------------

# Add an inline policy to the codebuild_role for S3 access
resource "aws_iam_role_policy" "codebuild_s3_policy" {
  name = "codebuild-s3-policy"
  role = aws_iam_role.codebuild_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::plantstore-codepipeline-artifacts/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:InitiateLayerUpload",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:UploadLayerPart",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:CompleteLayerUpload",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:PutImage",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:BatchCheckLayerAvailability",
      "Resource": "*"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Policies for CodePipeline Role
# ---------------------------------------------------------------------------------------------------------------------
# Add an inline policy to the codepipeline_role for S3 access
resource "aws_iam_role_policy" "codepipeline_s3_policy" {
  name = "codepipeline-s3-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::plantstore-codepipeline-artifacts/*"
      ]
    }
  ]
}
EOF
}

# inline policy for the codepipeline-role that specifically allows it to interact with CodeBuild
resource "aws_iam_role_policy" "codepipeline_codebuild_policy" {
  name = "codepipeline-codebuild-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild",
        "codebuild:BatchGetBuilds",
        "codebuild:StopBuild",
        "codebuild:ListBuildsForProject",
        "codebuild:BatchGetProjects"
      ],
      "Resource": [
        "arn:aws:codebuild:us-east-1:539247457480:project/plantstore-backend-build"
      ]
    }
  ]
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# Add an inline policy to the codebuild_role for CloudWatch Logs access
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "codebuild_logs_policy" {
  name = "codebuild-logs-policy"
  role = aws_iam_role.codebuild_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:us-east-1:539247457480:log-group:/aws/codebuild/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_connection_policy" {
  name = "codepipeline-connection-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = [
          aws_codestarconnections_connection.github_connection.arn,
          "arn:aws:codeconnections:us-east-1:539247457480:connection/4330607b-4aae-4812-ae7b-22b2375b28f6"
        ]
      },
      {
        Action = [
          "appconfig:StartDeployment",
          "appconfig:GetDeployment",
          "appconfig:StopDeployment"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "codecommit:GetRepository"
        ],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}
# ---------------------------------------------------------------------------------------------------------------------
# S3 Bucket for Artifacts
# ---------------------------------------------------------------------------------------------------------------------

# Create an S3 Bucket for Artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "plantstore-codepipeline-artifacts"
}

# ---------------------------------------------------------------------------------------------------------------------
# Docker hub access token
# ---------------------------------------------------------------------------------------------------------------------
# Create an AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "dockerhub_access_token" {
  name = "dockerhub-access-token"
}

resource "aws_secretsmanager_secret_version" "dockerhub_access_token_version" {
  secret_id     = aws_secretsmanager_secret.dockerhub_access_token.id
  secret_string = var.dockerhub_access_token
}

resource "aws_iam_policy" "codebuild_secrets_policy" {
  name        = "codebuild-secrets-policy"
  description = "Policy to allow CodeBuild to access Docker Hub access token"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = aws_secretsmanager_secret.dockerhub_access_token.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_secrets_access" {
  policy_arn = aws_iam_policy.codebuild_secrets_policy.arn
  role       = aws_iam_role.codebuild_role.name
}

# ---------------------------------------------------------------------------------------------------------------------
# Route 53 and ALB
# ---------------------------------------------------------------------------------------------------------------------
# Route 53 Hosted Zone for your domain
resource "aws_route53_zone" "savannah_canopy_zone" {
  name = "savannah-canopy.com" # domain name
}

# Route 53 Record for ALB (www.savannah-canopy.com)
resource "aws_route53_record" "www_savannah_canopy_record" {
  zone_id = aws_route53_zone.savannah_canopy_zone.zone_id
  name    = "www.savannah-canopy.com" # www subdomain
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}

# Request an SSL certificate for your domain
resource "aws_acm_certificate" "savannah_canopy_cert" {
  domain_name               = "www.savannah-canopy.com" # Fully qualified domain name
  validation_method         = "DNS"
  subject_alternative_names = ["savannah-canopy.com"]

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "application_load_balancer" {
  name               = "plantstore-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # subnets                    = ["subnet-004c597f51f5a111f", "subnet-015f9ef9f50348937"] # Replace with your subnets.Must be public
  subnets                    = aws_subnet.public[*].id
  enable_deletion_protection = false
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  # vpc_id      = "vpc-085257437561e6789" # VPC ID
  vpc_id = aws_vpc.main.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB Target Group for Backend
resource "aws_lb_target_group" "backend_target_group" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  # vpc_id      = "vpc-085257437561e6789" # VPC ID
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path     = "/actuator/health" #  backend healthcheck path
    protocol = "HTTP"
    port     = 8080
  }
}

# ALB Listener for HTTP (Redirect to HTTPS)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CodeBuild Projects
# ---------------------------------------------------------------------------------------------------------------------

# Define CodeBuild Projects
# CodeBuild projects , uses buildspec-backend.yml

resource "aws_codebuild_project" "backend_build" {
  name         = "plantstore-backend-build"
  service_role = aws_iam_role.codebuild_role.arn # codebuild role
  artifacts {
    type     = "CODEPIPELINE"
    location = aws_s3_bucket.codepipeline_bucket.id
    name     = "backend-output"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL" # for small instance
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "JAVA_HOME"
      value = "/usr/lib/jvm/java-17-amazon-corretto"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("../buildspec-backend.yml")
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# ECR Repositories
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecr_repository" "backend_registry" {
  name = "plantstore-backend-registry"
}

# ----------------------------------------------------------------------------------------------------------------------
# ECS Cluster
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "plantstore_cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# ECS Task Execution Role
# ----------------------------------------------------------------------------------------------------------------------

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_tasks_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the AWS managed policy for ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ----------------------------------------------------------------------------------------------------------------------
# ECS roles
# ----------------------------------------------------------------------------------------------------------------------
#IAM policy that grants the necessary ECS permissions.
resource "aws_iam_policy" "codepipeline_ecs_deploy_policy" {
  name        = "codepipeline-ecs-deploy-policy"
  description = "Policy to allow CodePipeline to deploy to ECS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "iam:PassRole",
          "elasticloadbalancing:*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = ["*"]
      },
      {
        Effect   = "Allow",
        Action   = ["iam:PassRole"],
        Resource = [aws_iam_role.ecs_tasks_execution_role.arn]
      }
    ]
  })
}

# Attach the newly created policy to the codepipeline_role
resource "aws_iam_role_policy_attachment" "codepipeline_ecs_deploy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_ecs_deploy_policy.arn
}

# ----------------------------------------------------------------------------------------------------------------------
# ECS Task Definitions and Adding CloudWatch Logging to ECS Task Definitions
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name : "backend",
      image : "${local.ecr_repository_url_backend}:latest",
      portMappings : [
        {
          "containerPort" : 8080,
          "hostPort" : 8080
        }
      ],
      essential : true,
      logConfiguration : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/backend-app",
          "awslogs-region" : "${data.aws_region.current.name}",
          "awslogs-stream-prefix" : "ecs"
        }
      },
      healthCheck : {
        "command" : ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health"],
        "interval" : 30,
        "timeout" : 10,
        "retries" : 3,
        "startPeriod" : 90
      },
      execute_command_configuration : {
        "logging" : "DEFAULT"
      }
    }
  ])
}

# ----------------------------------------------------------------------------------------------------------------------
# ECS Exec Policy
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "ecs_exec_policy"
  description = "Policy for ECS Exec functionality"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:StartSession",
          "ssm:UpdateInstanceInformation",
          "ssm:GetConnectionStatus",
          "ssm:sendCommand",
          "ssm:TerminateSession"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

# # ---------------------------------------------------------------------------------------------------------------------
# # ECS Services security groups
# # ---------------------------------------------------------------------------------------------------------------------
# Security Group for Backend Service
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for backend task service"
  # vpc_id      = "vpc-085257437561e6789" # Replace with your VPC ID
  vpc_id = aws_vpc.main.id


  # Allow inbound traffic on port 8080 from anywhere
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # ---------------------------------------------------------------------------------------------------------------------
# # ECS Services
# # ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "backend_service" {
  name                              = var.ecs_service_name_backend
  cluster                           = aws_ecs_cluster.plantstore_cluster.id
  task_definition                   = aws_ecs_task_definition.backend_task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 180

  network_configuration {
    # subnets          = ["subnet-004c597f51f5a111f"]       # Replace with your subnet IDs
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.backend_sg.id] # Replace with your security group IDs
    assign_public_ip = true
  }

  enable_execute_command = true


  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_target_group.arn
    container_name   = "backend"
    container_port   = 8080
  }

  # Controlling number of tasks deployed
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [
    aws_lb_target_group.backend_target_group,
    aws_lb_listener.http_listener
  ]
}

resource "aws_lb_listener_rule" "backend_listener_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }

  condition {
    host_header {
      values = ["www.savannah-canopy.com"]
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CodePipeline
# ---------------------------------------------------------------------------------------------------------------------

# AWS Code Conection
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "github-connection"
  provider_type = "GitHub"
}

# Define the CodePipeline with 3 stages
# Source Stage: Retrieves code from GitHub.
# Build Stage: Executes two actions—one for backend
# Deploy Stage: Deploys the built artifacts to an ECS cluster (replace with your ECS settings)-later on
resource "aws_codepipeline" "plantstore_pipeline" {
  name     = "plantstore-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  depends_on = [
    aws_codestarconnections_connection.github_connection,
    aws_iam_role_policy.codepipeline_connection_policy
  ]

  # --------------------------------------------------------------------------------------------------------------------
  # trigger the pipeline for any push or pull request event on any branch, affecting any file path
  # --------------------------------------------------------------------------------------------------------------------
  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "GitHub_Source"
      push {
        branches {
          includes = ["feature/backend"]
        }
      }

      #for pull_request triggers for merges into feature/test
      pull_request {
        events = ["CLOSED"] # Trigger on PR merging
        branches {
          includes = ["feature/backend"]
        }
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.id
    type     = "S3"
  }

  # adding pipeline type
  pipeline_type = "V2"

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        # ConnectionArn    = aws_codestarconnections_connection.github_connection.arn
        ConnectionArn    = "arn:aws:codeconnections:us-east-1:539247457480:connection/4330607b-4aae-4812-ae7b-22b2375b28f6"
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = "feature/backend"
      }
    }
  }


  stage {
    name = "Build_backend"

    action {
      name             = "Backend_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["backend_build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.backend_build.name
      }
    }
  }

  # ---------------------------------------------------------------------------------------------------------------------
  # Deploying to ECS
  # ---------------------------------------------------------------------------------------------------------------------
  stage {
    name = "Deploy_backend"

    action {
      name            = "Deploy_to_ECS_backend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["backend_build_output"]
      version         = "1"
      configuration = {
        ClusterName = aws_ecs_cluster.plantstore_cluster.name
        ServiceName = aws_ecs_service.backend_service.name
        FileName    = "imagedefinitions-backend.json"
      }
    }
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# CloudWatch Logs Subscription Filters and Lambda Functions (Terraform, Inline Code)
# ---------------------------------------------------------------------------------------------------------------------
# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role" # Name of the IAM role

  # IAM policy to allow Lambda to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com" # Allow Lambda service to assume this role
      }
    }]
  })
}

# Lambda Execution Policy
resource "aws_iam_policy_attachment" "lambda_execution_policy" {
  name       = "lambda-execution-policy"
  roles      = [aws_iam_role.lambda_execution_role.name]                          # Note: roles is a list ,attach policy to the Lambda execution role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # AWS managed policy for basic Lambda execution
}

# Add Bedrock invoke policy to the lambda role.
resource "aws_iam_policy" "lambda_bedrock_policy" {
  name        = "lambda-bedrock-policy"
  description = "Policy to allow Lambda to invoke Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel",
          "bedrock-runtime:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        Resource = "arn:aws:bedrock:us-east-1::foundation-model/${var.bedrock_model_id}" # model to use
      }
    ]
  })
}

# attaching lambda execution policy to the role
resource "aws_iam_role_policy_attachment" "lambda_bedrock_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_bedrock_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

#create the corresponding CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend-app"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_subscription_filter" "backend_log_subscription_filter" {
  name            = "backend-log-subscription-filter"                 # Name of the subscription filter
  log_group_name  = aws_cloudwatch_log_group.backend_log_group.name   # CloudWatch Log group to monitor (backend logs)
  filter_pattern  = "ERROR"                                           # Filter pattern to capture ERROR logs
  destination_arn = aws_lambda_function.bit_hound_ai_agent_lambda.arn # Ensure the ECS service is running before creating the filter
  depends_on      = [aws_ecs_service.backend_service]
}

# Lambda Permission for CloudWatch Logs (Backend)
resource "aws_lambda_permission" "allow_cloudwatch_logs_backend" {
  statement_id  = "AllowExecutionFromCloudWatchLogsBackend"                                                                                  # Unique ID for the permission statement
  action        = "lambda:InvokeFunction"                                                                                                    # Action to allow (invoke Lambda)
  function_name = aws_lambda_function.bit_hound_ai_agent_lambda.function_name                                                                # Lambda function name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"                                                                       # Principal that can invoke the Lambda
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/backend-app:*" # Source ARN for CloudWatch Logs
}

# ----------------------------------------------------------------------------------------------------------------------
# AI AGENT LAMBDA FUNCTION - >>>>> BIT- HOUND <<<
# ----------------------------------------------------------------------------------------------------------------------
# AI Agent Lambda Function
resource "aws_lambda_function" "bit_hound_ai_agent_lambda" {
  function_name    = "bit-hound-ai-agent-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 15
  source_code_hash = data.archive_file.bit_hound_lambda_zip.output_base64sha256
  s3_bucket        = aws_s3_bucket.codepipeline_bucket.id
  s3_key           = data.archive_file.bit_hound_lambda_zip.output_path
  depends_on       = [aws_s3_object.bit_hound_lambda_zip_upload]
  environment {
    variables = {
      GITHUB_TOKEN      = var.github_oauth_token # Ensure you have this variable defined
      GITHUB_REPO_OWNER = var.github_repo_owner
      GITHUB_REPO_NAME  = var.github_repo_name
      BEDROCK_MODEL_ID  = var.bedrock_model_id
      GITHUB_TOKEN      = var.github_oauth_token
    }
  }
  layers = [aws_lambda_layer_version.requests_layer.arn] # Attaching leyer
}

# Create zip file for  AI agent lambda function
data "archive_file" "bit_hound_lambda_zip" {
  type        = "zip"
  source_dir  = "./bit-hound-ai-agent"
  output_path = "bit-hound-ai-agent.zip"
}

# Upload AI agent zip to S3
resource "aws_s3_object" "bit_hound_lambda_zip_upload" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  key    = data.archive_file.bit_hound_lambda_zip.output_path
  source = data.archive_file.bit_hound_lambda_zip.output_path
  etag   = filemd5(data.archive_file.bit_hound_lambda_zip.output_path)
}

# Lambda Permission for Post Processing
resource "aws_lambda_permission" "allow_AI_agent_invocation" {
  statement_id  = "AllowExecutionFromAnywhere"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bit_hound_ai_agent_lambda.function_name
  principal     = "*" # Be mindful of security implications. Restrict as needed.
}

# -----------------------------------------------------------------------------------------------------------------------
# Adding custom request layer
# -----------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_layer_version" "requests_layer" {
  layer_name          = "requests-layer"
  description         = "Lambda layer with the requests module"
  compatible_runtimes = ["python3.9"]
  filename            = "requests-layer-dependencies.zip" # file is Terraform working directory
  source_code_hash    = filebase64sha256("requests-layer-dependencies.zip")
}

# -----------------------------------------------------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------------------------------------------------
# VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# internet gateway
#-----------------------------------------------------------------------------------------------------------------------

# Internet Gateway
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public-subnet-associations" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Test CodePipeline
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_codepipeline" "plantstore_pipeline_test" {
  name     = "plantstore-pipeline-test"
  role_arn = aws_iam_role.codepipeline_role.arn

  depends_on = [
    aws_codestarconnections_connection.github_connection,
    aws_iam_role_policy.codepipeline_connection_policy
  ]

  # --------------------------------------------------------------------------------------------------------------------
  # trigger the pipeline for any push or pull request event on the feature/test branch
  # --------------------------------------------------------------------------------------------------------------------
  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "GitHub_Source"
      push {
        branches {
          includes = ["feature/test"]
        }
      }
      #for pull_request triggers for merges into feature/test
      pull_request {
        events = ["CLOSED"] # Trigger on PR merging
        branches {
          includes = ["feature/test"]
        }
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.id # Reusing the same bucket
    type     = "S3"
  }

  pipeline_type = "V2" # Reusing V2

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source" # Action name within this pipeline
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output_test"] # Use a distinct artifact name
      configuration = {
        # ConnectionArn    = aws_codestarconnections_connection.github_connection.arn # Reusing the connection
        ConnectionArn    = "arn:aws:codeconnections:us-east-1:539247457480:connection/4330607b-4aae-4812-ae7b-22b2375b28f6"
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}" # Same repo
        BranchName       = "feature/test"                                     #Pointing to the test branch
      }
    }
  }

  stage {
    name = "Build_backend_test"

    action {
      name             = "Backend_Build_test"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output_test"]        # Match output artifact from Source stage
      output_artifacts = ["backend_build_output_test"] # Distinct build output artifact name
      version          = "1"
      configuration = {
        #Point to the existing build project.
        ProjectName = aws_codebuild_project.backend_build.name
      }
    }
  }

  stage {
    name = "Deploy_backend_test"

    action {
      name            = "Deploy_to_ECS_backend_test"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["backend_build_output_test"]
      version         = "1"
      configuration = {
        ClusterName = aws_ecs_cluster.plantstore_cluster.name   # Same cluster as production
        ServiceName = aws_ecs_service.backend_service_test.name # using the test service
        FileName    = "imagedefinitions-backend.json"
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS Service for Testing
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "backend_service_test" {
  # Use a distinct name for the test service
  name                              = "${var.ecs_service_name_backend}-test"   # Use a distinct name
  cluster                           = aws_ecs_cluster.plantstore_cluster.id    # Same cluster
  task_definition                   = aws_ecs_task_definition.backend_task.arn # Same task definition as production
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.backend_sg.id] # Reuse existing SG (ensure it allows access for testing)
    assign_public_ip = true                               #
  }

  enable_execute_command = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_target_group_test.arn # Point to the NEW test TG
    container_name   = "backend"                                         # Match container name in task definition
    container_port   = 8080
  }

  depends_on = [
    aws_lb_target_group.backend_target_group_test,
  aws_lb_listener.http_listener]
  # }
}

# ---------------------------------------------------------------------------------------------------------------------
# New Target Group for Test
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "backend_target_group_test" {
  name        = "backend-tg-test" # Distinct name
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path     = "/actuator/health"
    protocol = "HTTP"
    port     = 8080
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Listener Rule for Test
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "backend_listener_rule_test" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 15

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group_test.arn # Forward to the NEW test TG
  }

  condition {
    path_pattern {
      values = ["/test/"]
    }
  }

  # condition {
  #   host_header {
  #     values = ["www.savannah-canopy.com"]
  #   }
  # }
}
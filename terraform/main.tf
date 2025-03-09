# Define locals for ECR repository URLs
# Fetch the current AWS account ID
data "aws_caller_identity" "current" {}

# Fetch the current AWS region
data "aws_region" "current" {}

locals {
  ecr_repository_url_backend  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/plantstore-backend-registry"
  ecr_repository_url_frontend = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/plantstore-frontend-registry"
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
        "arn:aws:codebuild:us-east-1:539247457480:project/plantstore-backend-build",
        "arn:aws:codebuild:us-east-1:539247457480:project/plantstore-frontend-build"
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

# Grant CodeBuild Access to the Secret
# resource "aws_iam_role_policy_attachment" "codebuild_secrets_access" {
#   policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
#   role       = aws_iam_role.codebuild_role.name
# }

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
# CodeBuild Projects
# ---------------------------------------------------------------------------------------------------------------------

# Define CodeBuild Projects
# two CodeBuild projects—one for building the backend and one for the frontend , uses buildspec-backend.yml and
# buildspec-frontend.yml

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

resource "aws_codebuild_project" "frontend_build" {
  name         = "plantstore-frontend-build"
  service_role = aws_iam_role.codebuild_role.arn # codebuild role
  artifacts {
    type     = "CODEPIPELINE"
    location = aws_s3_bucket.codepipeline_bucket.id
    name     = "frontend-output"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "NODE_VERSION"
      value = "18"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("../buildspec-frontend.yml")
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# ECR Repositories
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecr_repository" "backend_registry" {
  name = "plantstore-backend-registry"
}

resource "aws_ecr_repository" "frontend_registry" {
  name = "plantstore-frontend-registry"
}

# ----------------------------------------------------------------------------------------------------------------------
# ECS Cluster
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "plantstore_cluster" {
  name = var.ecs_cluster_name
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
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "backend",
    "image": "${local.ecr_repository_url_backend}:latest",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/backend-app",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "frontend",
    "image": "${local.ecr_repository_url_frontend}:latest",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/frontend-app",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

# # ---------------------------------------------------------------------------------------------------------------------
# # ECS Services security groups
# # ---------------------------------------------------------------------------------------------------------------------
# Security Group for Backend Service
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for backend service"
  vpc_id      = "vpc-085257437561e6789" # Replace with your VPC ID

  # Allow inbound traffic on port 8080 from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Frontend Service
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Security group for frontend service"
  vpc_id      = "vpc-085257437561e6789" # Replace with your VPC ID

  # Allow inbound traffic on port 3000 from anywhere
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  name            = var.ecs_service_name_backend
  cluster         = aws_ecs_cluster.plantstore_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = ["subnet-004c597f51f5a111f"]       # Replace with your subnet IDs
    security_groups  = [aws_security_group.backend_sg.id] # Replace with your security group IDs
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "frontend_service" {
  name            = var.ecs_service_name_frontend
  cluster         = aws_ecs_cluster.plantstore_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = ["subnet-015f9ef9f50348937"]        # Replace with your subnet IDs
    security_groups  = [aws_security_group.frontend_sg.id] # Replace with your security group IDs
    assign_public_ip = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CodePipeline
# ---------------------------------------------------------------------------------------------------------------------

# Define the CodePipeline with 3 stages
# Source Stage: Retrieves code from GitHub.
# Build Stage: Executes two actions—one for backend and one for frontend.
# Deploy Stage: Deploys the built artifacts to an ECS cluster (replace with your ECS settings)-later on
resource "aws_codepipeline" "plantstore_pipeline" {
  name     = "plantstore-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

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
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        Owner      = var.github_repo_owner
        Repo       = var.github_repo_name
        Branch     = "main"
        OAuthToken = var.github_oauth_token
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

  stage {
    name = "Build_frontend"
    action {
      name             = "Frontend_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["frontend_build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.frontend_build.name
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

  stage {
    name = "Deploy_frontend"

    action {
      name            = "Deploy_to_ECS_frontend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["frontend_build_output"]
      version         = "1"
      configuration = {
        ClusterName = aws_ecs_cluster.plantstore_cluster.name
        ServiceName = aws_ecs_service.frontend_service.name
        FileName    = "imagedefinitions-frontend.json"
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CloudWatch Logs Subscription Filters and Lambda Functions (Terraform, Inline Code)
# ---------------------------------------------------------------------------------------------------------------------

# Lambda Function for Frontend Error Log Processing
# resource "aws_lambda_function" "frontend_error_logs_processor_lambda" {
#   function_name = "frontend-error-logs-processor-lambda" # Name of the Lambda function
#   role          = aws_iam_role.lambda_execution_role.arn # IAM role for Lambda execution
#   handler       = "lambda_function.lambda_handler"       # Handler function in the code
#   runtime       = "python3.9"                            # Runtime environment for Lambda
#   timeout       = 15                                     # Timeout for Lambda execution in seconds
#
#   # Inline Lambda code using zip and base64encode for deployment
#   filename         = "frontend_lambda_function.zip"                            # Name of the zip file
#   source_code_hash = data.archive_file.frontend_lambda_zip.output_base64sha256 # Hash of the source code for change detection
#
#   # Use the output of the archive_file data source directly
#   s3_bucket = aws_s3_bucket.codepipeline_bucket.id #use any s3 bucket that you have access to.
#   s3_key    = data.archive_file.frontend_lambda_zip.output_path
# }
#
# # Lambda Function for Backend Error Log Processing
# resource "aws_lambda_function" "backend_error_logs_processor_lambda" {
#   function_name = "backend-error-logs-processor-lambda"  # Name of the Lambda function
#   role          = aws_iam_role.lambda_execution_role.arn # IAM role for Lambda execution
#   handler       = "lambda_function.lambda_handler"       # Handler function in the code
#   runtime       = "python3.9"                            # Runtime environment for Lambda
#   timeout       = 15                                     # Timeout for Lambda execution in seconds
#
#   # Inline Lambda code using zip and base64encode for deployment
#   filename         = "backend_lambda_function.zip"                            # Name of the zip file
#   source_code_hash = data.archive_file.backend_lambda_zip.output_base64sha256 # Hash of the source code for change detection
#
#   # Use the output of the archive_file data source directly
#   s3_bucket = aws_s3_bucket.codepipeline_bucket.id #use any s3 bucket that you have access to.
#   s3_key    = data.archive_file.backend_lambda_zip.output_path
# }
# Lambda Function for Frontend Error Log Processing
# resource "aws_lambda_function" "frontend_error_logs_processor_lambda" {
#   function_name    = "frontend-error-logs-processor-lambda"
#   role             = aws_iam_role.lambda_execution_role.arn
#   handler          = "lambda_function.lambda_handler"
#   runtime          = "python3.9"
#   timeout          = 15
#   source_code_hash = data.archive_file.frontend_lambda_zip.output_base64sha256
#   s3_bucket        = aws_s3_bucket.codepipeline_bucket.id
#   s3_key           = data.archive_file.frontend_lambda_zip.output_path
# }
#
# # Lambda Function for Backend Error Log Processing
# resource "aws_lambda_function" "backend_error_logs_processor_lambda" {
#   function_name    = "backend-error-logs-processor-lambda"
#   role             = aws_iam_role.lambda_execution_role.arn
#   handler          = "lambda_function.lambda_handler"
#   runtime          = "python3.9"
#   timeout          = 15
#   source_code_hash = data.archive_file.backend_lambda_zip.output_base64sha256
#   s3_bucket        = aws_s3_bucket.codepipeline_bucket.id
#   s3_key           = data.archive_file.backend_lambda_zip.output_path
# }

# Lambda Function for Frontend Error Log Processing
resource "aws_lambda_function" "frontend_error_logs_processor_lambda" {
  function_name    = "frontend-error-logs-processor-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 15
  source_code_hash = data.archive_file.frontend_lambda_zip.output_base64sha256
  s3_bucket        = aws_s3_bucket.codepipeline_bucket.id
  s3_key           = data.archive_file.frontend_lambda_zip.output_path
  depends_on       = [aws_s3_object.frontend_lambda_zip_upload]
}

# Lambda Function for Backend Error Log Processing
resource "aws_lambda_function" "backend_error_logs_processor_lambda" {
  function_name    = "backend-error-logs-processor-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 15
  source_code_hash = data.archive_file.backend_lambda_zip.output_base64sha256
  s3_bucket        = aws_s3_bucket.codepipeline_bucket.id
  s3_key           = data.archive_file.backend_lambda_zip.output_path
  depends_on       = [aws_s3_object.backend_lambda_zip_upload]
}

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

# # CloudWatch Logs Subscription Filter for Frontend
# resource "aws_cloudwatch_log_subscription_filter" "frontend_log_subscription_filter" {
#   name            = "frontend-log-subscription-filter"                           # Name of the subscription filter
#   log_group_name  = "/ecs/frontend-app"                                          # CloudWatch Logs group to filter
#   filter_pattern  = "ERROR"                                                      # Filter pattern (empty for all logs)
#   destination_arn = aws_lambda_function.frontend_error_logs_processor_lambda.arn # Lambda function to send filtered logs to
# }
#
# # CloudWatch Logs Subscription Filter for Backend
# resource "aws_cloudwatch_log_subscription_filter" "backend_log_subscription_filter" {
#   name            = "backend-log-subscription-filter"                           # Name of the subscription filter
#   log_group_name  = "/ecs/backend-app"                                          # CloudWatch Logs group to filter
#   filter_pattern  = "ERROR"                                                     # Filter pattern (empty for all logs)
#   destination_arn = aws_lambda_function.backend_error_logs_processor_lambda.arn # Lambda function to send filtered logs to
# }

# ... (your existing code) ...

#create the corresponding CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend-app"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend-app"
  retention_in_days = 3
}


# CloudWatch Logs Subscription Filter for Frontend
# resource "aws_cloudwatch_log_subscription_filter" "frontend_log_subscription_filter" {
#   name            = "frontend-log-subscription-filter"                           # Name of the subscription filter
#   log_group_name  = "/ecs/frontend-app"                                          # CloudWatch Log group to monitor (frontend logs)
#   filter_pattern  = "ERROR"                                                      # Filter pattern to capture ERROR logs
#   destination_arn = aws_lambda_function.frontend_error_logs_processor_lambda.arn # Lambda function to send filtered logs to
#   depends_on      = [aws_ecs_service.frontend_service]                           # Ensure the ECS service is running before creating the filter
# }
#
# # CloudWatch Logs Subscription Filter for Backend
# resource "aws_cloudwatch_log_subscription_filter" "backend_log_subscription_filter" {
#   name            = "backend-log-subscription-filter"                           # Name of the subscription filter
#   log_group_name  = "/ecs/backend-app"                                          # CloudWatch Log group to monitor (backend logs)
#   filter_pattern  = "ERROR"                                                     # Filter pattern to capture ERROR logs
#   destination_arn = aws_lambda_function.backend_error_logs_processor_lambda.arn # Lambda function to send filtered logs to
#   depends_on      = [aws_ecs_service.backend_service]                           # Ensure the ECS service is running before creating the filter

resource "aws_cloudwatch_log_subscription_filter" "frontend_log_subscription_filter" {
  name            = "frontend-log-subscription-filter"
  log_group_name  = aws_cloudwatch_log_group.frontend_log_group.name
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.frontend_error_logs_processor_lambda.arn
  depends_on      = [aws_ecs_service.frontend_service]
}

resource "aws_cloudwatch_log_subscription_filter" "backend_log_subscription_filter" {
  name            = "backend-log-subscription-filter"
  log_group_name  = aws_cloudwatch_log_group.backend_log_group.name
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.backend_error_logs_processor_lambda.arn
  depends_on      = [aws_ecs_service.backend_service]
}


# ... (rest of your code) ...

# Lambda Permission for CloudWatch Logs (Frontend)
resource "aws_lambda_permission" "allow_cloudwatch_logs_frontend" {
  statement_id  = "AllowExecutionFromCloudWatchLogsFrontend"                                                                                  # Unique ID for the permission statement
  action        = "lambda:InvokeFunction"                                                                                                     # Action to allow (invoke Lambda)
  function_name = aws_lambda_function.frontend_error_logs_processor_lambda.function_name                                                      # Lambda function name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"                                                                        # Principal that can invoke the Lambda
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/frontend-app:*" # Source ARN for CloudWatch Logs
}

# Lambda Permission for CloudWatch Logs (Backend)
resource "aws_lambda_permission" "allow_cloudwatch_logs_backend" {
  statement_id  = "AllowExecutionFromCloudWatchLogsBackend"                                                                                  # Unique ID for the permission statement
  action        = "lambda:InvokeFunction"                                                                                                    # Action to allow (invoke Lambda)
  function_name = aws_lambda_function.backend_error_logs_processor_lambda.function_name                                                      # Lambda function name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"                                                                       # Principal that can invoke the Lambda
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/backend-app:*" # Source ARN for CloudWatch Logs
}

# Create zip file for frontend lambda function
data "archive_file" "frontend_lambda_zip" {
  type                    = "zip"
  source_content          = <<EOF
import json

def lambda_handler(event, context):
    log_events = event['awslogs']['data']
    decoded_logs = json.loads(log_events)
    for log_event in decoded_logs['logEvents']:
        message = log_event['message']
        if "ERROR" in message:
            print(message)
    return {
        'statusCode': 200,
        'body': json.dumps('Logs processed!')
    }
EOF
  output_path             = "frontend_lambda_function.zip"
  source_content_filename = "lambda_function.py"
}

# Upload frontend zip to S3
resource "aws_s3_object" "frontend_lambda_zip_upload" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  key    = data.archive_file.frontend_lambda_zip.output_path
  source = data.archive_file.frontend_lambda_zip.output_path
  etag   = filemd5(data.archive_file.frontend_lambda_zip.output_path)
}

# Create zip file for backend lambda function
data "archive_file" "backend_lambda_zip" {
  type                    = "zip"
  source_content          = <<EOF
import json

def lambda_handler(event, context):
    log_events = event['awslogs']['data']
    decoded_logs = json.loads(log_events)
    for log_event in decoded_logs['logEvents']:
        message = log_event['message']
        if "ERROR" in message:
            print(message)
    return {
        'statusCode': 200,
        'body': json.dumps('Logs processed!')
    }
EOF
  output_path             = "backend_lambda_function.zip"
  source_content_filename = "lambda_function.py"
}

# Upload backend zip to S3
resource "aws_s3_object" "backend_lambda_zip_upload" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  key    = data.archive_file.backend_lambda_zip.output_path
  source = data.archive_file.backend_lambda_zip.output_path
  etag   = filemd5(data.archive_file.backend_lambda_zip.output_path)
}
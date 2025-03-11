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

# Configure Route 53 A Records to Point to the ALB
# Route 53 Record for ALB (savannah-canopy.com)
# resource "aws_route53_record" "savannah_canopy_record" {
#   zone_id = aws_route53_zone.savannah_canopy_zone.zone_id
#   name    = "savannah-canopy.com" # domain name
#   type    = "A"
#
#   alias {
#     name                   = aws_lb.application_load_balancer.dns_name
#     zone_id                = aws_lb.application_load_balancer.zone_id
#     evaluate_target_health = true
#   }
# }

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
  name                       = "plantstore-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = ["subnet-004c597f51f5a111f", "subnet-015f9ef9f50348937"] # Replace with your subnets.Must be public
  enable_deletion_protection = false
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = "vpc-085257437561e6789" # VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS traffic"
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
  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "vpc-085257437561e6789" # VPC ID
  target_type = "ip"

  health_check {
    path     = "/api/payment/health" #  backend healthcheck path
    protocol = "HTTP"
    port     = 8080
  }
}

# ALB Target Group for Frontend
resource "aws_lb_target_group" "frontend_target_group" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = "vpc-085257437561e6789" #Replace with your VPC ID
  target_type = "ip"

  health_check {
    path     = "/" #  frontend healthcheck path
    protocol = "HTTP"
    port     = 3000
  }
}

# ALB Listener for HTTP (Redirect to HTTPS)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
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
    },
    "startCount": 1,
    "failureThreshold": 3,
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:8080/api/payment/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 60
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
    },
    "startCount": 1,
    "failureThreshold": 3,
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 60
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

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_target_group.arn
    container_name   = "backend"
    container_port   = 8080
  }

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
    path_pattern {
      values = ["/sc-bk/*"]
    }
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

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_target_group.frontend_target_group,
    aws_lb_listener.http_listener
  ]
}

resource "aws_lb_listener_rule" "frontend_listener_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 11

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/sc-ui/*"]
    }
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
  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }
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
  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }
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
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/frontend-app"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/backend-app"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_subscription_filter" "frontend_log_subscription_filter" {
  name            = "frontend-log-subscription-filter"                           # Name of the subscription filter
  log_group_name  = aws_cloudwatch_log_group.frontend_log_group.name             # CloudWatch Log group to monitor (frontend logs)
  filter_pattern  = "ERROR"                                                      # Filter pattern to capture ERROR logs
  destination_arn = aws_lambda_function.frontend_error_logs_processor_lambda.arn # Ensure the ECS service is running before creating the filter
  depends_on      = [aws_ecs_service.frontend_service]
}

resource "aws_cloudwatch_log_subscription_filter" "backend_log_subscription_filter" {
  name            = "backend-log-subscription-filter"                           # Name of the subscription filter
  log_group_name  = aws_cloudwatch_log_group.backend_log_group.name             # CloudWatch Log group to monitor (backend logs)
  filter_pattern  = "ERROR"                                                     # Filter pattern to capture ERROR logs
  destination_arn = aws_lambda_function.backend_error_logs_processor_lambda.arn # Ensure the ECS service is running before creating the filter
  depends_on      = [aws_ecs_service.backend_service]
}

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

# Create zip file for frontend AI agent lambda function
data "archive_file" "frontend_lambda_zip" {
  type                    = "zip"
  source_content          = <<EOF
# lambda function integrated with an AI agent
import json
import boto3
import base64
import os

lambda_client = boto3.client('lambda')

bedrock_runtime = boto3.client(service_name='bedrock-runtime')
model_id = os.environ['BEDROCK_MODEL_ID'] # get id from env variable

def lambda_handler(event, context):
    # Ensure the `awslogs` key exists
    if 'awslogs' not in event or 'data' not in event['awslogs']:
        print("Invalid event format: Missing 'awslogs.data'")
        return {'statusCode': 400, 'body': 'Invalid event format'}

    # Decode log data
    data = base64.b64decode(event['awslogs']['data'])
    log_data = json.loads(data)

    for log_event in log_data.get('logEvents', []):
        message = log_event.get('message', '')

        if "ERROR" in message:
            print(f"Error message: {message}")
            try:
                # Compiling a prompt
                prompt = f'As an software engineer Provide a solution and test cases for this error: {message}'

                payload = {
                    "prompt": f"<s>[INST] {prompt} [/INST]",
                    "max_tokens": 500,
                    "temperature": 0.5
                }
                # *** AI AGENT INVOCATION ***
                # The following call sends the error message as a prompt to the Amazon Bedrock model.
                # Agentic behavior.
                response = bedrock_runtime.invoke_model(
                    modelId=model_id,
                    accept='application/json',
                    contentType='application/json',
                    body=json.dumps(payload),
                )

                response_body = json.loads(response['body'].read())
                generated_text = response_body['outputs'][0]['text']
                # print(f"Bedrock response: {generated_text}")

                # *** INVOKE POST-PROCESSING LAMBDA ***
                invoke_response = lambda_client.invoke(
                    FunctionName='post-process-ai-agent-output-lambda',
                    InvocationType='RequestResponse',
                    Payload=json.dumps({'body': json.dumps({'generated_text': generated_text})})
                )

                post_process_result = json.loads(invoke_response['Payload'].read())
                print(f"Post-processed result: {post_process_result}")

            except Exception as e:
                print(f"Error invoking Bedrock: {e}")

# Return the AI agent's output.
    return {
        'statusCode': 200,
        'body': json.dumps({'generated_text': generated_text})
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

# Create zip file for backend AI agent lambda function
data "archive_file" "backend_lambda_zip" {
  type                    = "zip"
  source_content          = <<EOF
# lambda function integrated with an AI agent
import json
import boto3
import base64
import os

lambda_client = boto3.client('lambda')

bedrock_runtime = boto3.client(service_name='bedrock-runtime')
model_id = os.environ['BEDROCK_MODEL_ID'] # get id from env variable

def lambda_handler(event, context):
    # Ensure the `awslogs` key exists
    if 'awslogs' not in event or 'data' not in event['awslogs']:
        print("Invalid event format: Missing 'awslogs.data'")
        return {'statusCode': 400, 'body': 'Invalid event format'}

    # Decode log data
    data = base64.b64decode(event['awslogs']['data'])
    log_data = json.loads(data)

    for log_event in log_data.get('logEvents', []):
        message = log_event.get('message', '')

        if "ERROR" in message:
            print(f"Error message: {message}")
            try:

                # Compiling a prompt
                prompt = f'As an software engineer Provide a solution and test cases for this error: {message}'

                payload = {
                    "prompt": f"<s>[INST] {prompt} [/INST]",
                    "max_tokens": 500,
                    "temperature": 0.5
                }
                # *** AI AGENT INVOCATION ***
                # The following call sends the error message as a prompt to the Amazon Bedrock model.
                # # Agentic behavior.
                response = bedrock_runtime.invoke_model(
                    modelId=model_id,
                    accept='application/json',
                    contentType='application/json',
                    body=json.dumps(payload),
                )

                response_body = json.loads(response['body'].read())
                generated_text = response_body['outputs'][0]['text']
                # print(f"Bedrock response: {generated_text}")

                # *** INVOKE POST-PROCESSING LAMBDA ***
                invoke_response = lambda_client.invoke(
                    FunctionName='post-process-ai-agent-output-lambda',
                    InvocationType='RequestResponse',
                    Payload=json.dumps({'body': json.dumps({'generated_text': generated_text})})
                )

                post_process_result = json.loads(invoke_response['Payload'].read())
                print(f"Post-processed result: {post_process_result}")

            except Exception as e:
                print(f"Error invoking Bedrock: {e}")
    # Return the AI agent's output.
    return {
        'statusCode': 200,
        'body': json.dumps({'generated_text': generated_text})
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

# ----------------------------------------------------------------------------------------------------------------------
# Post agent processing
# ----------------------------------------------------------------------------------------------------------------------
# Lambda Permission for Frontend Error Logs Processor to invoke Post-Processing Lambda
resource "aws_lambda_permission" "allow_frontend_error_logs_invoke_post_process" {
  statement_id  = "AllowFrontendErrorLogsInvokePostProcess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_process_ai_agent_output_lambda.function_name
  principal     = "lambda.amazonaws.com"
  source_arn    = aws_lambda_function.frontend_error_logs_processor_lambda.arn
}

# Lambda Permission for Backend Error Logs Processor to invoke Post-Processing Lambda
resource "aws_lambda_permission" "allow_backend_error_logs_invoke_post_process" {
  statement_id  = "AllowBackendErrorLogsInvokePostProcess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_process_ai_agent_output_lambda.function_name
  principal     = "lambda.amazonaws.com"
  source_arn    = aws_lambda_function.backend_error_logs_processor_lambda.arn
}


# Lambda Function for Post-Processing AI Agent Output
resource "aws_lambda_function" "post_process_ai_agent_output_lambda" {
  function_name    = "post-process-ai-agent-output-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 15
  source_code_hash = data.archive_file.post_process_lambda_zip.output_base64sha256
  s3_bucket        = aws_s3_bucket.codepipeline_bucket.id
  s3_key           = data.archive_file.post_process_lambda_zip.output_path
  depends_on       = [aws_s3_object.post_process_lambda_zip_upload]
  environment {
    variables = {
      GITHUB_TOKEN      = var.github_oauth_token # Ensure you have this variable defined
      GITHUB_REPO_OWNER = var.github_repo_owner
      GITHUB_REPO_NAME  = var.github_repo_name
      FILE_PATH         = "savannah-canopy-rest/src/test" # Replace with your file path
      LINE_NUMBER       = "0"                             # Replace with your line number
    }
  }
}

# Create zip file for post processing AI agent lambda function
data "archive_file" "post_process_lambda_zip" {
  type                    = "zip"
  source_content          = <<EOF
import json
import os
import requests

def lambda_handler(event, context):
    try:
        # Extract environment variables
        github_token = os.environ['GITHUB_TOKEN']
        repo_owner = os.environ['GITHUB_REPO_OWNER']
        repo_name = os.environ['GITHUB_REPO_NAME']
        file_path = os.environ['FILE_PATH']
        line_number = int(os.environ['LINE_NUMBER'])

        # Extract the AI agent's output
        body = json.loads(event['body'])
        generated_text = json.loads(body['generated_text'])

        # Format the output (you can refine this part)
        formatted_text = f"\\n# AI Agent Suggestion:\\n{generated_text}\\n"
        print('generated_text')

        # Get the file content
        headers = {'Authorization': f'token {github_token}'}
        file_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}?ref=main'
        file_response = requests.get(file_url, headers=headers)
        file_response.raise_for_status()
        file_data = file_response.json()
        file_content = file_data['content']
        file_sha = file_data['sha']

        # Decode and modify the file content
        decoded_content = requests.get(file_data['download_url']).text.splitlines()
        decoded_content.insert(line_number - 1, formatted_text)
        updated_content = '\\n'.join(decoded_content).encode('utf-8')
        updated_content_base64 = base64.b64encode(updated_content).decode('utf-8')

        # Commit the changes to a new branch
        branch_name = f'ai-suggestion-{context.aws_request_id}'
        create_branch_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/git/refs'
        default_branch_sha = requests.get(f'https://api.github.com/repos/{repo_owner}/{repo_name}/git/refs/heads/main', headers=headers).json()['object']['sha']
        requests.post(create_branch_url, headers=headers, json={'ref': f'refs/heads/{branch_name}', 'sha': default_branch_sha}).raise_for_status()

        # Update the file in the new branch
        update_file_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}'
        requests.put(update_file_url, headers=headers, json={'message': 'AI agent suggestion', 'content': updated_content_base64, 'sha': file_sha, 'branch': branch_name}).raise_for_status()

        # Create the pull request
        create_pr_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/pulls'
        requests.post(create_pr_url, headers=headers, json={'title': 'AI agent suggestion', 'head': branch_name, 'base': 'feature/test'}).raise_for_status()

        return {'statusCode': 200, 'body': json.dumps({'message': 'Pull request created'})}

    except Exception as e:
        print(f"Error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
EOF
  output_path             = "post_process_lambda_function.zip"
  source_content_filename = "lambda_function.py"
}

# Upload post processing zip to S3
resource "aws_s3_object" "post_process_lambda_zip_upload" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  key    = data.archive_file.post_process_lambda_zip.output_path
  source = data.archive_file.post_process_lambda_zip.output_path
  etag   = filemd5(data.archive_file.post_process_lambda_zip.output_path)
}

# Lambda Permission for Post Processing
resource "aws_lambda_permission" "allow_post_processing_invocation" {
  statement_id  = "AllowExecutionFromAnywhere"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_process_ai_agent_output_lambda.function_name
  principal     = "*" # Be mindful of security implications. Restrict as needed.
}
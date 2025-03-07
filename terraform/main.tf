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
# IAM Policies for CodePipeline Role
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
    }
  ]
}
EOF
}

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
# ECS Task Definitions
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
    "image": "${var.ecr_repository_url_backend}:latest",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "essential": true
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
    "image": "${var.ecr_repository_url_frontend}:latest",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "essential": true
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
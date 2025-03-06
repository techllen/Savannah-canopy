# # credentials are fetched from credential file
# # provider configurations
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }
#
# # Configure the AWS Provider
# provider "aws" {
#   region = "us-east-1" # deployment region region
# }
#
# # ---------------------------------------------------------------------------------------------------------------------
# # IAM Role for CodePipeline for AWS to access github
# # ---------------------------------------------------------------------------------------------------------------------
# resource "aws_iam_role" "codepipeline_role" {
#   name = "codepipeline-role" # role  name
#
#   # allow codepipeline service to assume the role
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "codepipeline.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }
#
# # attaches the AWSCodePipelineFullAccess policy to the role, granting it the necessary permissions
# resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
#   role       = aws_iam_role.codepipeline_role.name
# }
# # --------------------------------------------------------------------------------------------------------------------
# # set up IAM roles, S3 bucket, CodeBuild projects, and CodePipeline
# # --------------------------------------------------------------------------------------------------------------------
#
# # IAM Role for CodeBuild
# resource "aws_iam_role" "codebuild_role" {
#   name = "codebuild-role"
#
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "codebuild.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }
#
# # Create an S3 Bucket for Artifacts
# resource "aws_s3_bucket" "codepipeline_bucket" {
#   bucket = "plantstore-codepipeline-artifacts"
# }
#
# # Define CodeBuild Projects
# # two CodeBuild projects—one for building the backend and one for the frontend , uses buildspec-backend.yml and
# # buildspec-frontend.yml
#
# resource "aws_codebuild_project" "backend_build" {
#   name         = "plantstore-backend-build"
#   service_role = aws_iam_role.codebuild_role.arn # codebuild role
#   artifacts {
#     type     = "CODEPIPELINE"
#     location = aws_s3_bucket.codepipeline_bucket.id
#     name     = "backend-output"
#   }
#   environment {
#     compute_type = "BUILD_GENERAL1_SMALL" # for small instance
#     image        = "aws/codebuild/standard:7.0"
#     type         = "LINUX_CONTAINER"
#     environment_variable {
#       name  = "JAVA_HOME"
#       value = "/usr/lib/jvm/java-17-amazon-corretto"
#     }
#   }
#   source {
#     type      = "CODEPIPELINE"
#     buildspec = file("../buildspec-backend.yml")
#   }
# }
#
# resource "aws_codebuild_project" "frontend_build" {
#   name         = "plantstore-frontend-build"
#   service_role = aws_iam_role.codebuild_role.arn # codebuild role
#   artifacts {
#     type     = "CODEPIPELINE"
#     location = aws_s3_bucket.codepipeline_bucket.id
#     name     = "frontend-output"
#   }
#   environment {
#     compute_type = "BUILD_GENERAL1_SMALL"
#     image        = "aws/codebuild/standard:7.0"
#     type         = "LINUX_CONTAINER"
#     environment_variable {
#       name  = "NODE_VERSION"
#       value = "18"
#     }
#   }
#   source {
#     type      = "CODEPIPELINE"
#     buildspec = file("../buildspec-frontend.yml")
#   }
# }
#
# # Define the CodePipeline with 3 stages
# # Source Stage: Retrieves code from GitHub.
# # Build Stage: Executes two actions—one for backend and one for frontend.
# # Deploy Stage: Deploys the built artifacts to an ECS cluster (replace with your ECS settings)-later on
# resource "aws_codepipeline" "plantstore_pipeline" {
#   name     = "plantstore-pipeline"
#   role_arn = aws_iam_role.codepipeline_role.arn
#
#   artifact_store {
#     location = aws_s3_bucket.codepipeline_bucket.id
#     type     = "S3"
#   }
#
#   stage {
#     name = "Source"
#
#     action {
#       name             = "GitHub_Source"
#       category         = "Source"
#       owner            = "ThirdParty"
#       provider         = "GitHub"
#       version          = "2"
#       output_artifacts = ["source_output"]
#       configuration = {
#         Owner      = var.github_repo_owner
#         Repo       = var.github_repo_name
#         Branch     = "main"
#         OAuthToken = var.github_oauth_token
#       }
#     }
#   }
#
#   stage {
#     name = "Build_backend"
#
#     action {
#       name             = "Backend_Build"
#       category         = "Build"
#       owner            = "AWS"
#       provider         = "CodeBuild"
#       input_artifacts  = ["source_output"]
#       output_artifacts = ["backend_build_output"]
#       version          = "1"
#       configuration = {
#         ProjectName = aws_codebuild_project.backend_build.name
#       }
#     }
#   }
#
#   stage {
#     name = "Build_frontend"
#     action {
#       name             = "Frontend_Build"
#       category         = "Build"
#       owner            = "AWS"
#       provider         = "CodeBuild"
#       input_artifacts  = ["source_output"]
#       output_artifacts = ["frontend_build_output"]
#       version          = "1"
#       configuration = {
#         ProjectName = aws_codebuild_project.frontend_build.name
#       }
#     }
#   }
#
#   # stage {
#   #   name = "Deploy"
#   #
#   #   action {
#   #     name            = "Deploy_to_ECS"
#   #     category        = "Deploy"
#   #     owner           = "AWS"
#   #     provider        = "ECS"
#   #     input_artifacts = ["backend_build_output", "frontend_build_output"]
#   #     version         = "1"
#   #     configuration = {
#   #       ClusterName = var.ecs_cluster_name   # Define in your variables
#   #       ServiceName = var.ecs_service_name   # Define in your variables
#   #       FileName    = "imagedefinitions.json"
#   #     }
#   #   }
#   # }
# }

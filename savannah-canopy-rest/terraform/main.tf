# credentials are fetched from credential file
# provider configurations
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

# IAM Role for CodePipeline for AWS to access github
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"  # role  name

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
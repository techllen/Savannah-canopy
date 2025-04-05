variable "github_oauth_token" {
  description = "GitHub OAuth Token for accessing the repository"
  type        = string
}

variable "github_repo_owner" {
  description = "Github user name"
  type        = string
}

variable "github_repo_name" {
  description = "Github repo name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster to deploy to"
  type        = string
  default     = "savannah-canopy"
}

variable "ecs_service_name" {
  description = "The name of the ECS service to update"
  type        = string
  default     = "savannah-canopy-service"
}

variable "ecs_service_name_backend" {
  description = "The name of the ECS service for the backend"
  default     = "plantstore-backend-service"
}

variable "ecs_service_name_frontend" {
  description = "The name of the ECS service for the frontend"
  default     = "plantstore-frontend-service"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

variable "dockerhub_access_token" {
  description = "Docker Hub Access Token"
  type        = string
}

variable "bedrock_model_id" {
  description = "The Bedrock model ID to use."
  type        = string
  default     = "mistral.mistral-7b-instruct-v0:2" # Default model
}

# database
variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

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

# variable "ecr_repository_url_backend" {
#   description = "The URL of the ECR repository for the backend"
#   default     = "539247457480.dkr.ecr.us-east-1.amazonaws.com/plantstore-backend-registry"
# }
#
# variable "ecr_repository_url_frontend" {
#   description = "The URL of the ECR repository for the frontend"
#   default     = "539247457480.dkr.ecr.us-east-1.amazonaws.com/plantstore-frontend-registry"
# }

variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}

variable "dockerhub_access_token" {
  description = "Docker Hub Access Token"
  type        = string
  sensitive   = true
}

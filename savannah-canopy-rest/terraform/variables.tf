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

# variable "ecs_cluster_name" {
#   description = "The name of the ECS cluster to deploy to"
#   type        = string
# }
#
# variable "ecs_service_name" {
#   description = "The name of the ECS service to update"
#   type        = string
# }

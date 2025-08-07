variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the runner will be deployed"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for runner registration"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "GitHub repository URL (e.g., https://github.com/owner/repo)"
  type        = string
}

variable "aks_cluster_id" {
  description = "ID of the AKS cluster the runner needs access to"
  type        = string
}

variable "container_registry_id" {
  description = "ID of the container registry (optional)"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Switzerland North"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "origin_hostname" {
  description = "The hostname of the origin server (e.g., agent.reisdematos.ch)"
  type        = string
  default     = "agent.reisdematos.ch"
}

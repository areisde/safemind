# Core configuration
variable "name" {
  description = "Base name for all resources"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for globally scoped resources"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# GPT-4o Model configuration
variable "gpt4o_deployment_name" {
  description = "Name for the GPT-4o deployment"
  type        = string
  default     = "gpt-4o"
}

variable "gpt4o_version" {
  description = "Version of GPT-4o model to deploy"
  type        = string
  default     = "2024-11-20"  # Latest GPT-4o version
}

variable "gpt4o_capacity" {
  description = "Capacity (TPM) for GPT-4o deployment with Global Standard"
  type        = number
  default     = 50  # 50K tokens per minute for Global Standard
  validation {
    condition     = var.gpt4o_capacity >= 1 && var.gpt4o_capacity <= 500
    error_message = "GPT-4o Global Standard capacity must be between 1 and 500 (in thousands of TPM)."
  }
}

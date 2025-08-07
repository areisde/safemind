# ────────────────────────────────────────────────
# Core parameters
# ────────────────────────────────────────────────
variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "switzerlandnorth"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ────────────────────────────────────────────────
# AKS parameters
# ────────────────────────────────────────────────
variable "node_count" {
  description = "Number of nodes in default node pool"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

# ────────────────────────────────────────────────
# Feature toggles
# ────────────────────────────────────────────────
variable "enable_llm" {
  description = "Enable Azure OpenAI service"
  type        = bool
  default     = true
}

variable "enable_frontdoor" {
  description = "Enable Azure Front Door for external access"
  type        = bool
  default     = false  # Start disabled, enable when ready
}

variable "frontdoor_origin_hostname" {
  description = "The hostname of the origin server for Front Door"
  type        = string
  default     = "agent.reisdematos.ch"
}

variable "enable_observability" {
  type    = bool
  default = false
}

variable "enable_gateway" {
  type    = bool
  default = false
}

variable "enable_guardrail" {
  type    = bool
  default = false
}
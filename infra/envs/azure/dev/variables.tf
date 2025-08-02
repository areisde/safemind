# ────────────────────────────────────────────────
# Core parameters
# ────────────────────────────────────────────────
variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "switzerlandnorth"
}

variable "suffix" {
  description = "Uniqueness suffix for globally-scoped names (storage account, AKS, etc.)"
  type        = string
  # empty by default – script can generate random suffix at runtime
  default     = ""
}

# ────────────────────────────────────────────────
# Feature toggles  (start with everything off)
# ────────────────────────────────────────────────
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

variable "enable_llm" {
  type    = bool
  default = false
}

# ────────────────────────────────────────────────
# Azure OpenAI (only meaningful if enable_llm=true)
# ────────────────────────────────────────────────
#variable "aoai_name" {
#  description = "Name of existing Azure OpenAI resource"
#  type        = string
#  default     = ""          # leave blank until you enable LLM
#}

#variable "aoai_deployment" {
#  description = "Deployment name inside the AOAI resource"
#  type        = string
#  default     = ""
#}

# ────────────────────────────────────────────────
# Kubernetes cluster sizing
# ────────────────────────────────────────────────
variable "k8s_version" {
  description = "AKS Kubernetes minor version"
  type        = string
  default     = "1.32.6"
}

variable "node_size" {
  description = "VM SKU for the default node-pool"
  type        = string
  # D4s_v5 → 4 vCPU, 16 GiB RAM – good starter size
  default     = "Standard_B2s"
}

variable "enable_auto_scaling" {
    description = "Auto scaling of nodes"
    type = bool
    default = true
}

variable "min_nodes" {
  description = "Minimum node count for autoscaler"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum node count for autoscaler"
  type        = number
  default     = 2
}
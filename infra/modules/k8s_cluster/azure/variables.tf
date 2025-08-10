variable "name" {
  description = "AKS cluster name (also used for DNS prefix and default resource-group name if none provided)"
  type        = string
}

variable "location" {
  description = "Azure region, e.g. westus2 or switzerlandnorth"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the default node-pool will be deployed"
  type        = string
}

variable "k8s_version" {
  description = "Exact Kubernetes version or major.minor (e.g. 1.29)"
  type        = string
}

variable "node_size" {
  description = "VM SKU for the default node-pool (e.g. Standard_D4s_v5, Standard_NC4as_T4_v3 for GPUs)"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "enable_auto_scaling" {
  description = "Auto scaling enabled"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Minimum node count for the autoscaler"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum node count for the autoscaler"
  type        = number
  default     = 3
}

variable "resource_group_name" {
  description = <<EOT
Optional: existing Resource Group in which the AKS cluster will be created.
Leave empty to let the module create its own RG called "<name>-aks-rg".
EOT
  type    = string
  default = ""
}

# Spot Instance Configuration
variable "enable_spot_instances" {
  description = "Enable spot instance node pool for cost optimization"
  type        = bool
  default     = true
}

variable "spot_node_size" {
  description = "VM SKU for the spot node pool"
  type        = string
  default     = "Standard_D2s_v3"  # 2 vCPUs, 8GB RAM - widely available for spot instances
}

variable "spot_max_nodes" {
  description = "Maximum number of spot nodes"
  type        = number
  default     = 2
}

variable "spot_max_price" {
  description = "Maximum price per hour for spot instances (in USD). Set to -1 for market price"
  type        = number
  default     = 0.04  # ~$29/month per node maximum (D2s_v3 pricing)
}
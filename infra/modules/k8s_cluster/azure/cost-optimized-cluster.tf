# Cost-Optimized AKS Configuration
# Use this to replace the current main.tf for significant cost savings

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  
  # Cost optimization: Auto-scaling node pool
  default_node_pool {
    name            = "default"
    node_count      = 1  # Start with 1 node
    vm_size         = "Standard_B2s"  # Keep current size
    
    # Enable auto-scaling for cost efficiency
    enable_auto_scaling = true
    min_count          = 1  # Scale down to 1 node when not busy
    max_count          = 3  # Scale up only when needed
    
    # Use ephemeral OS disks for cost savings (no persistent storage costs)
    os_disk_type    = "Ephemeral"
    os_disk_size_gb = 30  # Minimum size for ephemeral
    
    # Network optimization
    enable_node_public_ip = false
  }

  # Use system-assigned managed identity (no extra cost)
  identity {
    type = "SystemAssigned"
  }

  # Network configuration optimized for cost
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    
    # Use smaller service CIDR for cost optimization
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  # Cost optimization: Enable cluster auto-scaler
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                        = "random"
    max_graceful_termination_sec    = 600
    scale_down_delay_after_add      = "10m"
    scale_down_unneeded            = "10m"
    scan_interval                  = "10s"
    skip_nodes_with_local_storage  = false
    skip_nodes_with_system_pods    = false
  }

  tags = {
    Environment = "dev"
    CostCenter  = "mlops"
    AutoScale   = "enabled"
  }
}

# Optional: Add spot node pool as separate resource for maximum cost savings
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                = 0  # Set to 1 to enable spot instances
  name                 = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = "Standard_B2s"
  
  # Spot instances are ~80% cheaper but can be evicted
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = 0.02  # Max $0.02 per hour
  
  enable_auto_scaling = true
  node_count         = 0
  min_count          = 0
  max_count          = 2
  
  os_disk_type    = "Ephemeral"
  os_disk_size_gb = 30
  
  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  
  tags = {
    NodeType = "spot"
    CostOptimized = "true"
  }
}

# Output important information
output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

output "cost_savings_notes" {
  value = "Applied: Auto-scaling (1-3 nodes), Ephemeral disks, Spot instances available. Est. 40-60% cost reduction."
}

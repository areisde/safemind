/*
 * Azure-specific implementation of the generic k8s_cluster module.
 * Creates:  - Resource Group (unless you pass one)
 *           - AKS cluster with a single node pool
 *           - Outputs kubeconfig strings so callers can configure kubectl / Helm
 */

# Resource Group (optional: create if name not supplied)
resource "azurerm_resource_group" "aks_rg" {
  count    = var.resource_group_name == "" ? 1 : 0
  name     = "${var.name}-aks-rg"
  location = var.location
}

locals {
  rg_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.aks_rg[0].name
}

# AKS cluster
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = local.rg_name
  dns_prefix          = "${var.name}-dns"

  kubernetes_version  = var.k8s_version

  default_node_pool {
    name                = "cpu"
    node_count          = var.min_nodes
    vm_size             = var.node_size
    min_count           = var.min_nodes
    max_count           = var.max_nodes
    vnet_subnet_id      = var.subnet_id
    orchestrator_version = var.k8s_version
    tags = {
      env = "dev"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    provisioner = "terraform"
  }
}

# Spot node pool for cost-effective auto-scaling
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.enable_spot_instances ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size              = var.spot_node_size
  
  # Auto-scaling configuration
  enable_auto_scaling = true
  min_count          = 0  # Scale to zero when not needed
  max_count          = var.spot_max_nodes
  
  # Spot instance configuration
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = var.spot_max_price  # Max price per hour
  
  # Performance and cost optimization
  os_disk_type    = "Ephemeral"  # Faster and cheaper storage
  os_disk_size_gb = 30
  
  # Network configuration
  vnet_subnet_id = var.subnet_id
  
  # Taints to ensure workloads opt-in to spot instances
  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  
  tags = {
    provisioner = "terraform"
    nodeType    = "spot"
    costOptimized = "true"
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "kube_host" {
  value = azurerm_kubernetes_cluster.this.kube_config.0.host
}

output "kube_client_cert" {
  value     = azurerm_kubernetes_cluster.this.kube_config.0.client_certificate
  sensitive = true
}

output "kube_client_key" {
  value     = azurerm_kubernetes_cluster.this.kube_config.0.client_key
  sensitive = true
}

output "kube_ca" {
  value = azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate
}

# Concatenated kubeconfig YAML (useful for kubectl export)
output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}

# AKS Managed Identity for integration with other Azure services
output "managed_identity_principal_id" {
  description = "Principal ID of the AKS managed identity"
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "managed_identity_tenant_id" {
  description = "Tenant ID of the AKS managed identity"
  value       = azurerm_kubernetes_cluster.this.identity[0].tenant_id
}
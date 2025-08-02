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
    enable_auto_scaling = var.enable_auto_scaling
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
terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm",    version = "~> 3.117" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.13" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.30" }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstorage26698"
    container_name       = "state"
    key                  = "dev-azure.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── 1) Resource Group ────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "mlops-dev-rg"
  location = var.location
  
  tags = {
    Environment = "dev"
    Project     = "mlops"
    Owner       = "reisdematos"
  }
}

# ── 2) Network Infrastructure ────────────────────────────────────────────────
resource "azurerm_virtual_network" "main" {
  name                = "vnet-mlops-dev"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = "dev"
    Project     = "mlops"
    Owner       = "reisdematos"
  }
}

resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "virtual_nodes" {
  name                 = "subnet-virtual-nodes"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
  
  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# ── 3) AKS Cluster with Azure AD Integration ─────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-mlops-dev"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix         = "aks-mlops-dev"
  
  # Public API server endpoint with Azure AD authentication (secure)
  private_cluster_enabled = false
  
  # Enable RBAC and Azure AD integration for proper security
  role_based_access_control_enabled = true
  local_account_disabled = false  # Allow local accounts for easier management
  
  # Enable Azure AD integration for modern authentication
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }
  
  # Use custom VNet for private networking
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_B2s"
    node_count          = 1  # Minimal for system pods only
    vnet_subnet_id      = azurerm_subnet.aks.id
    
    # System node pool for essential services
    only_critical_addons_enabled = false
    enable_auto_scaling = false
    
    node_labels = {}
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable workload identity for secure pod access
  workload_identity_enabled = true
  oidc_issuer_enabled      = true

  # Enable Virtual Nodes (ACI Connector)
  # Note: This requires the virtual nodes subnet with proper delegation
  # Uncomment to enable virtual nodes for serverless scaling
  # addon_profile {
  #   aci_connector_linux {
  #     enabled     = true
  #     subnet_name = azurerm_subnet.virtual_nodes.name
  #   }
  # }

  # Configure cluster autoscaler for better responsiveness
  auto_scaler_profile {
    balance_similar_node_groups      = false
    expander                        = "least-waste"  # Choose cheapest nodes first
    max_graceful_termination_sec    = "600"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "0s"           # Scale immediately when pods pending
    scale_down_delay_after_add     = "5m"           # Wait 5 min before scaling down new nodes
    scale_down_delay_after_delete  = "10s"          # Quick scale down after node deletion
    scale_down_delay_after_failure = "3m"           # Retry quickly after failure
    scan_interval                  = "10s"          # Check every 10 seconds
    scale_down_utilization_threshold = 0.5          # Scale down if utilization < 50%
    skip_nodes_with_local_storage  = false
    skip_nodes_with_system_pods    = true           # Don't remove system nodes
  }

  tags = {
    Environment = "dev"
    Project     = "mlops"
    Owner       = "reisdematos"
  }
}

# ── Spot Node Pool for Cost-Effective Auto-Scaling ──────────────────────────
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = "Standard_D2s_v3"  # 2 vCPU, 8GB RAM - minimum for Kubernetes
  
  # Auto-scaling configuration - scales to zero when not needed
  enable_auto_scaling = true
  min_count          = 0   # 🔥 KEY: Can scale to ZERO = $0 cost when idle
  max_count          = 3   # Up to 3 extra nodes for burst capacity (smaller nodes)
  
  # Spot instance configuration (up to 90% cost savings)
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = 0.04  # Max $0.04/hour (~$29/month per node) - D2s_v3 pricing
  
  # Performance and cost optimization
  os_disk_type    = "Ephemeral"  # Faster and cheaper storage
  os_disk_size_gb = 30
  
  # Network configuration
  vnet_subnet_id = azurerm_subnet.aks.id
  
  # Taint spot nodes so workloads must explicitly opt-in
  # This ensures critical system pods stay on regular nodes
  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  
  tags = {
    Environment    = "dev"
    Project        = "mlops"
    Owner          = "reisdematos"
    NodeType       = "spot"
    CostOptimized  = "true"
  }
}

# ── Azure AD RBAC Configuration ──────────────────────────────────────────────
data "azurerm_client_config" "current" {}

# Grant the GitHub Actions service principal cluster admin role
resource "azurerm_role_assignment" "github_actions_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ── 4) Azure OpenAI Service ──────────────────────────────────────────────────
module "llm_endpoint" {
  count = var.enable_llm ? 1 : 0
  
  source = "../../../modules/llm_endpoint/azure"
  
  name     = "aoai-mlops-dev"
  location = var.location
  suffix   = "26698"
  
  tags = {
    Environment = "dev"
    Project     = "mlops"
    Owner       = "reisdematos"
  }
}

# ── 5) Azure Front Door (configured via variables) ───────────────────────────
module "frontdoor" {
  count = var.enable_frontdoor ? 1 : 0
  
  source = "../../../modules/frontdoor/azure"

  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  environment        = var.environment
  origin_hostname    = var.frontdoor_origin_hostname
}

# ── 6) GitHub Self-Hosted Runner (deployed via GitHub Actions) ───────────────
# Note: The runner is deployed directly from GitHub Actions workflow
# using the built-in GITHUB_TOKEN and repository context for security

# ── Kubernetes & Helm Providers ─────────────────────────────────────────────
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
  }
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

# Azure OpenAI outputs (when enabled)
output "azure_openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  value       = var.enable_llm ? module.llm_endpoint[0].azure_openai_endpoint : null
}

output "azure_openai_api_key" {
  description = "Azure OpenAI API key"
  value       = var.enable_llm ? module.llm_endpoint[0].azure_openai_primary_key : null
  sensitive   = true
}

output "gpt4o_deployment_name" {
  description = "GPT-4o deployment name"
  value       = var.enable_llm ? module.llm_endpoint[0].gpt4o_deployment_name : null
}

# Front Door outputs (when enabled)
output "frontdoor_endpoint_hostname" {
  description = "Azure Front Door endpoint hostname"
  value       = var.enable_frontdoor ? module.frontdoor[0].frontdoor_endpoint_hostname : null
}

output "frontdoor_endpoint_url" {
  description = "Azure Front Door endpoint URL"
  value       = var.enable_frontdoor ? module.frontdoor[0].frontdoor_endpoint_url : null
}

# Network outputs for connectivity
output "virtual_network_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}
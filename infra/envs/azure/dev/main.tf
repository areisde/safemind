terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm   = { source = "hashicorp/azurerm",    version = "~> 3.117" }
    helm      = { source = "hashicorp/helm",       version = "~> 2.13" }
    kubernetes= { source = "hashicorp/kubernetes", version = "~> 2.30" }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstorage26698"   # << literal; script passes actual SA via -backend-config
    container_name       = "state"
    key                  = "dev-azure.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── 1) VNet (flat) ────────────────────────────────────────────────────────────
module "network" {
  source     = "../../../modules/network/azure"
  name       = "vnet-dev"
  location   = var.location
  vnet_cidr  = "10.50.0.0/22"
}

# ── 2) AKS cluster (with autoscaler; virtual-node optional in module) ─────────
module "k8s" {
  source         = "../../../modules/k8s_cluster/azure"
  name           = "k8s-dev"
  location       = var.location
  subnet_id      = module.network.subnet_id
  k8s_version    = var.k8s_version
  node_size      = var.node_size
  enable_auto_scaling = var.enable_auto_scaling
  min_nodes      = var.min_nodes
  max_nodes      = var.max_nodes
}

# kubeconfig output from module is used by helm_release resources
provider "kubernetes" {
  host                   = module.k8s.kube_host
  client_certificate     = base64decode(module.k8s.kube_client_cert)
  client_key             = base64decode(module.k8s.kube_client_key)
  cluster_ca_certificate = base64decode(module.k8s.kube_ca)
}

provider "helm" {
  kubernetes {
    host                   = module.k8s.kube_host
    client_certificate     = base64decode(module.k8s.kube_client_cert)
    client_key             = base64decode(module.k8s.kube_client_key)
    cluster_ca_certificate = base64decode(module.k8s.kube_ca)
  }
}

# ── 3) Observability (optional) ───────────────────────────────────────────────
#module "observability" {
#  count       = var.enable_observability ? 1 : 0
#  source      = "../../../modules/observability"
#}
#  namespace   = "monitoring"

# ── 4) Kong gateway (optional) ────────────────────────────────────────────────
#module "gateway_kong" {
#  count       = var.enable_gateway ? 1 : 0
#  source      = "../../../modules/gateway_kong"
#  namespace   = "gateway"
#  replicas    = 1
#}

# ── 5) Guardrail FastAPI (optional) ───────────────────────────────────────────
#module "guardrail" {
#  count       = var.enable_guardrail ? 1 : 0
#  source      = "../../../modules/guardrail_fastapi"
#  namespace   = "guardrail"
#  replicas    = 1
#}

# ── 6) Azure OpenAI private endpoint (optional) ───────────────────────────────
#module "llm_endpoint" {
#  count          = var.enable_llm ? 1 : 0
#  source         = "../../../modules/llm_endpoint"
#  cloud          = "azure"
#  namespace      = "llm"
#  vnet_subnet_id = module.network.subnet_id
#  aoai_name      = var.aoai_name
#  aoai_deployment= var.aoai_deployment
#}

# Convenience: write kubeconfig to file for local kubectl
output "kubeconfig" {
  value     = module.k8s.kubeconfig
  sensitive = true
}
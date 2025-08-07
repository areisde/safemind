# Azure Container Instance Self-Hosted GitHub Runner

resource "azurerm_container_group" "github_runner" {
  name                = "github-runner-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  subnet_ids          = [var.subnet_id]
  os_type             = "Linux"

  container {
    name   = "github-runner"
    image  = "myoung34/github-runner:latest"
    cpu    = "1.0"
    memory = "2.0"

    environment_variables = {
      RUNNER_NAME_PREFIX = "aci-runner-${var.environment}"
      REPO_URL          = var.github_repo_url
      RUNNER_SCOPE      = "repo"
      LABELS            = "self-hosted,azure,aci,private-cluster"
      EPHEMERAL         = "true"
    }

    secure_environment_variables = {
      ACCESS_TOKEN = var.github_token
    }

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Project     = "mlops"
    Purpose     = "github-self-hosted-runner"
    Owner       = "reisdematos"
  }
}

# Role assignment for AKS access
resource "azurerm_role_assignment" "aks_contributor" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Contributor Role"
  principal_id         = azurerm_container_group.github_runner.identity[0].principal_id
}

# Role assignment for container registry access (if needed)
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.container_registry_id != null ? 1 : 0
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_group.github_runner.identity[0].principal_id
}

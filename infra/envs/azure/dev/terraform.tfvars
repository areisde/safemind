# Azure region for deployment
location = "switzerlandnorth"

# Unique suffix for globally scoped resources (optional)
suffix = "areisde"

# Kubernetes cluster configuration
k8s_version = "1.28"
node_size = "Standard_B2s"
enable_auto_scaling = true
min_nodes = 1
max_nodes = 5

# Feature toggles - enable the services you want to deploy
enable_observability = true
enable_gateway = true  
enable_guardrail = true
enable_llm = true

# Azure OpenAI configuration (if enable_llm = true)
gpt4o_deployment_name = "gpt-4o"
gpt4o_version = "2024-08-06"
gpt4o_capacity = 10

# Tags for resources
tags = {
  Environment = "dev"
  Project     = "mlops"
  ManagedBy   = "terraform"
  Owner       = "areisde"
}

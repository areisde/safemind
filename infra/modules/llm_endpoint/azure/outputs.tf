# Azure OpenAI Service outputs
output "azure_openai_endpoint" {
  description = "Endpoint URL of the Azure OpenAI service"
  value       = azurerm_cognitive_account.aoai.endpoint
}

output "azure_openai_primary_key" {
  description = "Primary API key for Azure OpenAI service"
  value       = azurerm_cognitive_account.aoai.primary_access_key
  sensitive   = true
}

output "gpt4o_deployment_name" {
  description = "Name of the GPT-4o deployment"
  value       = azurerm_cognitive_deployment.gpt4o.name
}

# Simple config for LLM applications
output "llm_config" {
  description = "Configuration object for LLM applications"
  value = {
    provider         = "azure"
    endpoint         = azurerm_cognitive_account.aoai.endpoint
    api_version      = "2024-08-01-preview"
    deployment_name  = azurerm_cognitive_deployment.gpt4o.name
    model           = "gpt-4o"
  }
}

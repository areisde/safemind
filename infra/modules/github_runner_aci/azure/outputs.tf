output "container_group_id" {
  description = "ID of the container group"
  value       = azurerm_container_group.github_runner.id
}

output "container_group_name" {
  description = "Name of the container group"
  value       = azurerm_container_group.github_runner.name
}

output "runner_identity_principal_id" {
  description = "Principal ID of the runner's managed identity"
  value       = azurerm_container_group.github_runner.identity[0].principal_id
}

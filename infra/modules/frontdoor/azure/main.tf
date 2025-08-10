# Azure Front Door Standard Implementation

# Create Front Door Profile (Standard)
resource "azurerm_cdn_frontdoor_profile" "mlops" {
  name                = "mlops-frontdoor-standard"
  resource_group_name = var.resource_group_name
  sku_name           = "Standard_AzureFrontDoor"

  tags = {
    Environment = "production"
    Project     = "mlops-ai"
    Owner       = "reisdematos"
  }
}

# Create Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "mlops_api" {
  name                     = "mlops-api"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mlops.id
  enabled                  = true

  tags = {
    Purpose = "AI-API-Gateway"
  }
}

# Create Origin Group pointing to your current setup
resource "azurerm_cdn_frontdoor_origin_group" "aks_backend" {
  name                     = "aks-backend"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mlops.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

  health_probe {
    interval_in_seconds = 100
    path               = "/healthz"  # Correct health check endpoint
    protocol           = "Http"     # Use HTTP instead of HTTPS
    request_type       = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                       = 4
    successful_samples_required       = 3
  }
}

# Create Origin pointing to configurable hostname  
resource "azurerm_cdn_frontdoor_origin" "aks_origin" {
  name                           = "aks-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.aks_backend.id
  enabled                        = true

  certificate_name_check_enabled = false  # Disable cert check for IP-based origin
  host_name                     = var.origin_hostname
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = "agent.reisdematos.ch"  # Use custom domain as host header
  priority                      = 1
  weight                        = 1000
}

# Basic Rule Set for Security (Standard tier limitations)
resource "azurerm_cdn_frontdoor_rule_set" "security_rules" {
  name                     = "SecurityRules"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mlops.id
}

# Rule: Block suspicious user agents
resource "azurerm_cdn_frontdoor_rule" "block_bots" {
  depends_on = [azurerm_cdn_frontdoor_rule_set.security_rules]

  name                      = "BlockBots"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.security_rules.id
  order                     = 1
  behavior_on_match        = "Stop"

  conditions {
    request_header_condition {
      header_name      = "User-Agent"
      operator         = "Contains"
      match_values     = ["curl", "wget", "python-requests", "bot", "crawler", "spider"]
      negate_condition = false
    }
  }

  actions {
    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-Blocked-Reason"
      value         = "Suspicious User Agent"
    }
    
    route_configuration_override_action {
      cache_behavior                = "OverrideAlways"
      cache_duration                = "00:00:00"  # No caching for blocked requests
      cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks_backend.id
      forwarding_protocol           = "HttpsOnly"
    }
  }
}

# Rule: Add security headers
resource "azurerm_cdn_frontdoor_rule" "security_headers" {
  depends_on = [azurerm_cdn_frontdoor_rule_set.security_rules]

  name                      = "SecurityHeaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.security_rules.id
  order                     = 2
  behavior_on_match        = "Continue"

  conditions {
    request_method_condition {
      operator         = "Equal"
      match_values     = ["GET", "POST"]
      negate_condition = false
    }
  }

  actions {
    response_header_action {
      header_action = "Append"
      header_name   = "X-Content-Type-Options"
      value         = "nosniff"
    }
    
    response_header_action {
      header_action = "Append"
      header_name   = "X-Frame-Options"
      value         = "DENY"
    }
    
    response_header_action {
      header_action = "Append"
      header_name   = "X-XSS-Protection"
      value         = "1; mode=block"
    }
  }
}

# Create Route with security rules
resource "azurerm_cdn_frontdoor_route" "mlops_route" {
  name                       = "mlops-route"
  cdn_frontdoor_endpoint_id  = azurerm_cdn_frontdoor_endpoint.mlops_api.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.aks_backend.id
  cdn_frontdoor_origin_ids   = [azurerm_cdn_frontdoor_origin.aks_origin.id]
  enabled                    = true

  forwarding_protocol    = "HttpOnly"    # Use HTTP to backend
  https_redirect_enabled = true
  patterns_to_match     = ["/*"]
  supported_protocols   = ["Http", "Https"]

  # Apply security rules
  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.security_rules.id]

  # Associate with custom domain
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.custom_domain.id]

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                = ["timestamp", "session_id", "user_id"]
    compression_enabled          = true
    content_types_to_compress    = [
      "application/json",
      "text/plain",
      "text/html",
      "application/javascript",
      "text/css"
    ]
  }
}

# Custom Domain Configuration
resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  name                     = "agent-reisdematos-ch"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.mlops.id
  dns_zone_id              = null  # Using external DNS provider (Cloudflare)
  host_name                = "agent.reisdematos.ch"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# Outputs
output "frontdoor_endpoint_hostname" {
  description = "The hostname of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.mlops_api.host_name
}

output "frontdoor_endpoint_url" {
  description = "The full URL to access your AI services securely"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.mlops_api.host_name}"
}

output "frontdoor_profile_id" {
  description = "The Front Door profile ID"
  value       = azurerm_cdn_frontdoor_profile.mlops.id
}

# ────────────────────────────────────────────────
# Core Configuration
# ────────────────────────────────────────────────
location    = "switzerlandnorth"
environment = "dev"

# ────────────────────────────────────────────────
# AKS Configuration (Single Node - Cost Optimized)
# ────────────────────────────────────────────────
node_count = 1              # Single node only to minimize costs
node_size  = "Standard_B2s"  # ~$30/month total cost

# ────────────────────────────────────────────────
# Feature Toggles
# ────────────────────────────────────────────────
enable_llm           = true   # Enable Azure OpenAI deployment
enable_frontdoor     = true  # Enable Azure Front Door (external access)
enable_observability = true  # Enable monitoring stack
enable_gateway       = true   # Enable Kong gateway

# ────────────────────────────────────────────────
# Front Door Configuration (if enabled)
# ────────────────────────────────────────────────
# Note: Kong LoadBalancer IP is updated automatically by GitHub Actions after deployment
frontdoor_origin_hostname    = "0.0.0.0"  # Placeholder - updated by workflow



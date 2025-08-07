# ────────────────────────────────────────────────
# Core Configuration
# ────────────────────────────────────────────────
location    = "switzerlandnorth"
environment = "dev"

# ────────────────────────────────────────────────
# AKS Configuration (Cost Optimized)
# ────────────────────────────────────────────────
node_count = 1              # Start with 1 node
node_size  = "Standard_B2s"  # Good balance of performance vs cost

# ────────────────────────────────────────────────
# Feature Toggles
# ────────────────────────────────────────────────
enable_llm           = true   # Enable Azure OpenAI deployment
enable_frontdoor     = false  # Enable Azure Front Door (external access)
enable_observability = false  # Enable monitoring stack
enable_gateway       = true   # Enable Kong gateway

# ────────────────────────────────────────────────
# Front Door Configuration (if enabled)
# ────────────────────────────────────────────────
frontdoor_origin_hostname = "agent.reisdematos.ch"

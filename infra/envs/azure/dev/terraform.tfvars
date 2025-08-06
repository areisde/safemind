suffix               = "26698"           # must be unique for storage account
enable_observability = false
enable_gateway       = false
enable_guardrail     = false
enable_llm           = true              # Enable Azure OpenAI deployment

# Azure OpenAI Configuration
gpt4o_deployment_name = "gpt-4o"
gpt4o_version        = "2024-11-20"
gpt4o_capacity       = 50

# Tags
tags = {
  Environment = "dev"
  Project     = "mlops"
  Owner       = "your-name"
  Purpose     = "MLOps Platform with LLM"
}
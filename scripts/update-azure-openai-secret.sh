#!/bin/bash

# Update Azure OpenAI Secret from Terraform Outputs
# Run this after deploying Azure OpenAI with Terraform

set -e

echo "🔧 Updating Azure OpenAI Kubernetes secret from Terraform outputs..."

# Navigate to Terraform directory
cd infra/envs/azure/dev

# Check if LLM is enabled
ENABLE_LLM=$(terraform output -raw enable_llm 2>/dev/null || echo "false")

if [ "$ENABLE_LLM" != "true" ]; then
    echo "❌ LLM module is not enabled. Set enable_llm=true in terraform.tfvars"
    exit 1
fi

# Get Terraform outputs
ENDPOINT=$(terraform output -raw azure_openai_endpoint)
API_KEY=$(terraform output -raw azure_openai_api_key)
DEPLOYMENT_NAME=$(terraform output -raw gpt4o_deployment_name)

echo "✅ Got Azure OpenAI configuration:"
echo "   Endpoint: $ENDPOINT"
echo "   Deployment: $DEPLOYMENT_NAME"

# Navigate back to project root
cd ../../../../

# Update the Kubernetes secret
kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig delete secret azure-openai-config -n llm --ignore-not-found=true

kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig create secret generic azure-openai-config -n llm \
  --from-literal=AZURE_OPENAI_ENDPOINT="$ENDPOINT" \
  --from-literal=AZURE_OPENAI_API_KEY="$API_KEY" \
  --from-literal=AZURE_OPENAI_DEPLOYMENT_NAME="$DEPLOYMENT_NAME" \
  --from-literal=AZURE_OPENAI_API_VERSION="2024-08-01-preview" \
  --from-literal=AZURE_OPENAI_MODEL="gpt-4o"

echo "✅ Azure OpenAI secret updated successfully!"
echo "🚀 You can now restart the llm-proxy pods to pick up the new configuration:"
echo "   kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig rollout restart deployment/llm-proxy -n llm"

#!/bin/bash

# Cloud Setup Helper Script
# This script helps set up the prerequisites for cloud deployment

set -e

echo "🚀 MLOps Cloud Deployment Setup"
echo "================================"

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        exit 1
    else
        echo "✅ $1 is installed"
    fi
}

echo "Checking prerequisites..."
check_tool "az"
check_tool "terraform"
check_tool "kubectl"
check_tool "docker"
check_tool "gh"  # GitHub CLI for setting secrets

# Login to Azure
echo "🔐 Logging into Azure..."
az login

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📋 Using subscription: $SUBSCRIPTION_ID"

# Create service principal for GitHub Actions
echo "🤖 Creating service principal for GitHub Actions..."
SP_OUTPUT=$(az ad sp create-for-rbac --name "github-actions-mlops-$(date +%s)" \
  --role Contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth)

echo "💾 Service principal created. Please save this output as AZURE_CREDENTIALS secret:"
echo "$SP_OUTPUT"

# Create Terraform state storage
echo "📦 Setting up Terraform state storage..."
STORAGE_TIMESTAMP=$(date +%s)
STORAGE_ACCOUNT="tfstorage$STORAGE_TIMESTAMP"

az group create --name "tfstate-rg" --location "switzerlandnorth" > /dev/null
az storage account create \
  --resource-group "tfstate-rg" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --encryption-services blob > /dev/null

az storage container create \
  --name "state" \
  --account-name "$STORAGE_ACCOUNT" > /dev/null

echo "✅ Terraform state storage created: $STORAGE_ACCOUNT"

# Set GitHub secrets (requires GitHub CLI)
echo "🔑 Setting up GitHub secrets..."

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
    echo "⚠️  GitHub CLI is not authenticated."
    echo "Please run: gh auth login"
    echo "Then re-run this script."
    echo ""
    echo "📝 For now, please manually set these GitHub secrets in your repo:"
    echo "  Go to: https://github.com/areisde/mlops/settings/secrets/actions"
    echo "  AZURE_CREDENTIALS: (the service principal JSON output above)"
    echo "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
    echo "  TERRAFORM_STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
    echo "  TERRAFORM_STATE_RG: tfstate-rg"
    echo "  GRAFANA_ADMIN_PASSWORD: (choose a secure password)"
    echo ""
    read -p "Press Enter after you've set up the secrets manually..."
else
    echo "✅ GitHub CLI is authenticated"
    read -p "Do you want to automatically set GitHub secrets? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Setting GitHub secrets..."
        echo "$SP_OUTPUT" | gh secret set AZURE_CREDENTIALS
        echo "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID
        echo "$STORAGE_ACCOUNT" | gh secret set TERRAFORM_STORAGE_ACCOUNT
        echo "tfstate-rg" | gh secret set TERRAFORM_STATE_RG
        
        read -s -p "Enter Grafana admin password: " GRAFANA_PASSWORD
        echo
        echo "$GRAFANA_PASSWORD" | gh secret set GRAFANA_ADMIN_PASSWORD
        
        echo "✅ GitHub secrets configured!"
    else
        echo "📝 Please manually set these GitHub secrets:"
        echo "  Go to: https://github.com/areisde/mlops/settings/secrets/actions"
        echo "  AZURE_CREDENTIALS: (the service principal JSON output above)"
        echo "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
        echo "  TERRAFORM_STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
        echo "  TERRAFORM_STATE_RG: tfstate-rg"
        echo "  GRAFANA_ADMIN_PASSWORD: (choose a secure password)"
    fi
fi

# Update Terraform variables
echo "📝 Updating Terraform variables..."
cat > infra/envs/azure/dev/terraform.tfvars << EOF
# Azure region for deployment
location = "switzerlandnorth"

# Unique suffix for globally scoped resources
suffix = "$(whoami)"

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
  Owner       = "$(whoami)"
}
EOF

echo "✅ Terraform variables updated!"

# Update Helm chart values with correct repository owner
GITHUB_USER=$(gh api user --jq .login 2>/dev/null || echo "YOUR_USERNAME")
echo "🐙 Updating Helm charts for GitHub user: $GITHUB_USER"

# Update guardrail chart
sed -i.bak "s|repository: ghcr.io/areisde/guardrail|repository: ghcr.io/$GITHUB_USER/guardrail|" charts/guardrail/values.yaml
# Update llm-proxy chart  
sed -i.bak "s|repository: ghcr.io/areisde/llm-proxy|repository: ghcr.io/$GITHUB_USER/llm-proxy|" charts/llm-proxy/values.yaml

echo "✅ Helm charts updated!"

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Review and commit the updated terraform.tfvars and values.yaml files"
echo "2. Push to main branch to trigger deployment: git push origin main"
echo "3. Monitor deployment in GitHub Actions"
echo "4. Access services using: kubectl get services -A"
echo "5. Check Promtail logs: kubectl logs -n observability ds/promtail-unified"
echo ""
echo "📚 For detailed instructions, see docs/CLOUD-DEPLOYMENT.md"

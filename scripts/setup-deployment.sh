#!/bin/bash

# MLOps Platform Setup Script
# This script helps new users set up the MLOps platform in their Azure subscription

set -e

echo "🚀 MLOps Platform Setup"
echo "======================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}Checking prerequisites...${NC}"
    
    command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI is required but not installed.${NC}" >&2; exit 1; }
    command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}" >&2; exit 1; }
    command -v helm >/dev/null 2>&1 || { echo -e "${RED}Helm is required but not installed.${NC}" >&2; exit 1; }
    
    echo -e "${GREEN}✓ All prerequisites found${NC}"
}

# Check Azure login
check_azure_login() {
    echo -e "\n${YELLOW}Checking Azure authentication...${NC}"
    
    if ! az account show >/dev/null 2>&1; then
        echo -e "${YELLOW}Please login to Azure:${NC}"
        az login
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    echo -e "${GREEN}✓ Logged in to Azure subscription: ${SUBSCRIPTION_NAME}${NC}"
    echo -e "Subscription ID: ${SUBSCRIPTION_ID}"
}

# Setup Terraform configuration
setup_terraform_config() {
    echo -e "\n${YELLOW}Setting up Terraform configuration...${NC}"
    
    cd infra/envs/azure/dev
    
    if [ ! -f terraform.tfvars ]; then
        if [ -f terraform.tfvars.example ]; then
            cp terraform.tfvars.example terraform.tfvars
            echo -e "${YELLOW}Created terraform.tfvars from example.${NC}"
            echo -e "${YELLOW}Please edit terraform.tfvars with your values:${NC}"
            echo "  - subscription_id = \"$SUBSCRIPTION_ID\""
            echo "  - location = \"your-preferred-region\""
            echo "  - resource_prefix = \"your-initials\""
            
            read -p "Press enter when you've updated terraform.tfvars..."
        else
            echo -e "${RED}terraform.tfvars.example not found${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ terraform.tfvars already exists${NC}"
    fi
    
    cd - >/dev/null
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "\n${YELLOW}Deploying Azure infrastructure...${NC}"
    
    cd infra/envs/azure/dev
    
    echo "Initializing Terraform..."
    terraform init
    
    echo "Planning deployment..."
    terraform plan
    
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply
        echo -e "${GREEN}✓ Infrastructure deployed successfully${NC}"
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
    
    cd - >/dev/null
}

# Get Kubernetes credentials
setup_kubernetes() {
    echo -e "\n${YELLOW}Setting up Kubernetes access...${NC}"
    
    cd infra/envs/azure/dev
    
    # Extract resource group and cluster name from Terraform output
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)
    
    echo "Getting AKS credentials..."
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --file ./kubeconfig --overwrite-existing
    
    echo "Testing Kubernetes connection..."
    kubectl --kubeconfig=./kubeconfig get nodes
    
    echo -e "${GREEN}✓ Kubernetes access configured${NC}"
    
    cd - >/dev/null
}

# Deploy MLOps services
deploy_services() {
    echo -e "\n${YELLOW}Deploying MLOps services...${NC}"
    
    KUBECONFIG_PATH="infra/envs/azure/dev/kubeconfig"
    
    echo "Deploying observability stack..."
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f observability/
    
    echo "Waiting for observability services to be ready..."
    kubectl --kubeconfig="$KUBECONFIG_PATH" wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=grafana -n observability
    
    echo "Deploying MLOps services..."
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f charts/guardrail/ || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f charts/llm-proxy/ || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f charts/gateway/ || true
    
    echo -e "${GREEN}✓ MLOps services deployed${NC}"
}

# Show access information
show_access_info() {
    echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
    echo "========================"
    
    KUBECONFIG_PATH="infra/envs/azure/dev/kubeconfig"
    
    echo -e "\n${YELLOW}Access Information:${NC}"
    
    # Get service URLs
    echo "Getting service endpoints..."
    kubectl --kubeconfig="$KUBECONFIG_PATH" get svc -A
    
    # Check if LLM is enabled and update secret
    cd infra/envs/azure/dev
    ENABLE_LLM=$(terraform output -json | grep -o '"enable_llm".*true' || echo "")
    cd - >/dev/null
    
    if [ -n "$ENABLE_LLM" ]; then
        echo -e "\n${YELLOW}Setting up Azure OpenAI integration...${NC}"
        ./scripts/update-azure-openai-secret.sh
    fi
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "1. Run: ./scripts/open-dashboards.sh"
    echo "2. Test deployment: ./scripts/test-llm-analytics.sh"
    echo "3. Check services: kubectl --kubeconfig=$KUBECONFIG_PATH get pods -A"
    
    if [ -n "$ENABLE_LLM" ]; then
        echo "4. Test Azure OpenAI: curl -X POST http://localhost:8001/generate -H 'Content-Type: application/json' -d '{\"prompt\":\"Hello!\",\"max_tokens\":50}'"
    fi
    
    echo -e "\n${YELLOW}Documentation:${NC}"
    echo "- Full deployment guide: docs/DEPLOYMENT.md"
    echo "- Architecture overview: docs/ARCHITECTURE.md"
}

# Main execution
main() {
    check_prerequisites
    check_azure_login
    setup_terraform_config
    deploy_infrastructure
    setup_kubernetes
    deploy_services
    show_access_info
}

# Run main function
main "$@"

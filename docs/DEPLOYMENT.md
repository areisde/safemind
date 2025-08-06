# MLOps Platform Deployment Guide

This guide helps you deploy the MLOps platform to your own Azure subscription.

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0
- kubectl installed
- Helm 3.x installed
- Docker installed (for local development)

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd mlops
```

### 2. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create service principal for Terraform (optional but recommended)
az ad sp create-for-rbac --name "terraform-mlops" --role Contributor --scopes /subscriptions/your-subscription-id
```

### 3. Configure Terraform Variables

```bash
# Copy and edit terraform variables
cd infra/envs/azure/dev
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

Required variables:
- `subscription_id`: Your Azure subscription ID
- `location`: Azure region (e.g., "East US")
- `resource_prefix`: Your initials or short identifier
- `project_name`: Project name (default: "mlops")

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

### 5. Get Kubernetes Access

```bash
# Get AKS credentials
az aks get-credentials --resource-group rg-mlops-dev --name aks-mlops-dev --file ./kubeconfig

# Verify connection
kubectl --kubeconfig=./kubeconfig get nodes
```

### 6. Deploy MLOps Services

```bash
# Return to project root
cd ../../../../

# Install observability stack
kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig apply -f observability/

# Deploy MLOps services
kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig apply -f charts/guardrail/
kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig apply -f charts/llm-proxy/

# Setup Kong gateway
kubectl --kubeconfig=infra/envs/azure/dev/kubeconfig apply -f charts/gateway/
```

### 7. Access Services

```bash
# Get service URLs
./scripts/open-dashboards.sh

# Test the deployment
./scripts/test-llm-analytics.sh
```

## Environment-Specific Configurations

### Development Environment
- Single node cluster
- Basic monitoring
- Local storage

### Production Environment
- Multi-node cluster with auto-scaling
- Advanced monitoring and alerting
- Persistent storage with backup
- Network policies and security

## Customization

### Changing Resource Names
Edit `variables.tf` to modify default resource naming patterns.

### Adding New Services
1. Create new Helm chart in `charts/`
2. Add service configuration to observability
3. Update deployment scripts

### Scaling Configuration
Modify `terraform.tfvars`:
```hcl
node_count = 5
node_vm_size = "Standard_DS3_v2"
```

## Troubleshooting

### Common Issues

1. **Terraform Authentication**
   ```bash
   az login
   az account show
   ```

2. **Kubernetes Access**
   ```bash
   kubectl --kubeconfig=./kubeconfig cluster-info
   ```

3. **Service Discovery**
   ```bash
   kubectl --kubeconfig=./kubeconfig get pods -A
   ```

### Clean Up

```bash
# Destroy infrastructure
cd infra/envs/azure/dev
terraform destroy
```

## Security Considerations

- Never commit `kubeconfig`, `terraform.tfvars`, or any `.env` files
- Use Azure Key Vault for secrets in production
- Enable Azure Policy for compliance
- Configure network security groups appropriately
- Use managed identities for service authentication

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Azure and Kubernetes logs
3. Open an issue in the repository

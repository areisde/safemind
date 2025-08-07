# Cloud Deployment Setup Guide

## Prerequisites

1. **Azure Account** with sufficient permissions
2. **GitHub Repository** with Actions enabled
3. **Local Tools:**
   - Azure CLI
   - Terraform >= 1.7
   - kubectl
   - Docker

## Step-by-Step Cloud Deployment

### 1. Azure Service Principal Setup

```bash
# Login to Azure
az login

# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "github-actions-mlops" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth

# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-mlops" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

### 2. Terraform State Storage Setup

```bash
# Create resource group for Terraform state
az group create --name "tfstate-rg" --location "East US"

# Create storage account for Terraform state
az storage account create \
  --resource-group "tfstate-rg" \
  --name "tfstorage$(date +%s)" \
  --sku Standard_LRS \
  --encryption-services blob

# Create storage container
az storage container create \
  --name "state" \
  --account-name "tfstorage<YOUR_TIMESTAMP>"
```

### 3. GitHub Secrets Configuration

Add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `AZURE_CREDENTIALS` | Service principal JSON | Output from step 1 |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | `az account show --query id -o tsv` |
| `TERRAFORM_STORAGE_ACCOUNT` | Terraform state storage account | Name from step 2 |
| `TERRAFORM_STATE_RG` | Terraform state resource group | `tfstate-rg` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | Choose a secure password |

### 4. Update Terraform Variables

Edit `infra/envs/azure/dev/terraform.tfvars`:

```hcl
subscription_id = "YOUR_SUBSCRIPTION_ID"
location = "East US"
resource_prefix = "your-initials"
project_name = "mlops"
k8s_version = "1.28"
node_size = "Standard_B2s"
enable_auto_scaling = true
min_nodes = 1
max_nodes = 5
```

### 5. Container Registry Setup

Your images will be pushed to GitHub Container Registry (GHCR) automatically. Ensure your repository visibility allows package access:

1. Go to your repo settings
2. Navigate to `Actions > General`
3. Under "Workflow permissions", select "Read and write permissions"
4. Check "Allow GitHub Actions to create and approve pull requests"

### 6. Deploy to Cloud

#### Option A: Manual Deployment (First Time)

```bash
# Deploy infrastructure
cd infra/envs/azure/dev
terraform init -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT"
terraform plan
terraform apply

# Get AKS credentials
az aks get-credentials --resource-group k8s-dev-aks-rg --name k8s-dev

# Build and push images
docker build -t ghcr.io/YOUR_USERNAME/guardrail:latest services/guardrail
docker build -t ghcr.io/YOUR_USERNAME/llm-proxy:latest services/llm-proxy
docker push ghcr.io/YOUR_USERNAME/guardrail:latest
docker push ghcr.io/YOUR_USERNAME/llm-proxy:latest

# Deploy services using Helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy observability
kubectl create namespace observability
helm install loki grafana/loki -n observability -f observability/config/loki.yaml
kubectl apply -f observability/promtail-rbac.yaml
kubectl apply -f observability/config/promtail.yaml
helm install prometheus prometheus-community/prometheus -n observability
helm install grafana grafana/grafana -n observability --set adminPassword=YOUR_PASSWORD

# Deploy MLOps services
kubectl create namespace llm
helm install guardrail charts/guardrail -n llm
helm install llm-proxy charts/llm-proxy -n llm

# Apply security policies
kubectl apply -f security/
```

#### Option B: Automated Deployment (Subsequent)

Simply push to the `main` branch:

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

### 7. Access Your Services

After deployment, get service URLs:

```bash
# Get external IPs
kubectl get services -A

# Get ingress URLs
kubectl get ingress -A

# Port forward for local access (if needed)
kubectl port-forward -n observability svc/grafana 3000:80
kubectl port-forward -n llm svc/llm-proxy 8080:80
```

### 8. Monitoring and Maintenance

#### View Logs
```bash
# Application logs
kubectl logs -n llm deployment/guardrail
kubectl logs -n llm deployment/llm-proxy

# Infrastructure logs
kubectl logs -n kube-system -l app=azure-cni-networkmonitor
```

#### Scale Services
```bash
# Scale MLOps services
kubectl scale deployment guardrail -n llm --replicas=3
kubectl scale deployment llm-proxy -n llm --replicas=3

# Scale AKS nodes (if needed)
az aks scale --resource-group k8s-dev-aks-rg --name k8s-dev --node-count 3
```

#### Update Services
```bash
# Update image tags and push to trigger deployment
git tag v1.1.0
git push origin v1.1.0
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Azure credentials are correct
   - Check service principal permissions
   - Ensure subscription ID is correct

2. **Terraform State Issues**
   - Verify storage account exists and is accessible
   - Check backend configuration in Terraform

3. **Kubernetes Access Issues**
   - Verify AKS cluster is running
   - Check kubeconfig is valid
   - Ensure network connectivity

4. **Image Pull Errors**
   - Verify GHCR permissions
   - Check image names and tags
   - Ensure imagePullSecrets are configured

5. **Helm Deployment Failures**
   - Check values.yaml configuration
   - Verify chart dependencies
   - Review Kubernetes events: `kubectl get events`

### Monitoring Commands

```bash
# Check overall cluster health
kubectl get nodes
kubectl get pods -A

# Monitor deployments
kubectl get deployments -A
kubectl describe deployment guardrail -n llm

# Check resource usage
kubectl top nodes
kubectl top pods -A
```

## Next Steps

1. **Set up monitoring alerts** in Grafana
2. **Configure backup strategies** for persistent data
3. **Implement proper secret management** with Azure Key Vault
4. **Set up SSL/TLS certificates** for secure access
5. **Configure autoscaling** based on metrics
6. **Implement disaster recovery** procedures

## Architecture Components

After deployment, you'll have:

- **AKS Cluster**: Managed Kubernetes cluster
- **Container Images**: Stored in GitHub Container Registry
- **Observability Stack**: Prometheus, Grafana, Loki
- **MLOps Services**: Guardrail and LLM Proxy
- **Security Policies**: Network policies, rate limiting
- **Gateway**: Kong for traffic management
- **CI/CD Pipeline**: Automated deployment via GitHub Actions

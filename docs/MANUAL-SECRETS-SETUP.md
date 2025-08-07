# Manual GitHub Secrets Setup Guide

If you prefer to set up GitHub secrets manually or if the automated script fails, follow these steps:

## 1. Navigate to Repository Secrets

Go to: [https://github.com/areisde/mlops/settings/secrets/actions](https://github.com/areisde/mlops/settings/secrets/actions)

## 2. Add the Following Secrets

Click "New repository secret" for each of these:

### AZURE_CREDENTIALS
```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret", 
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```
(Use the output from the service principal creation command)

### AZURE_SUBSCRIPTION_ID
Your Azure subscription ID (can get with `az account show --query id -o tsv`)

### TERRAFORM_STORAGE_ACCOUNT
The storage account name created for Terraform state (format: `tfstorage<timestamp>`)

### TERRAFORM_STATE_RG
```
tfstate-rg
```

### GRAFANA_ADMIN_PASSWORD
Choose a secure password for Grafana admin access

## 3. Verify Secrets

After adding all secrets, you should see:
- AZURE_CREDENTIALS
- AZURE_SUBSCRIPTION_ID  
- TERRAFORM_STORAGE_ACCOUNT
- TERRAFORM_STATE_RG
- GRAFANA_ADMIN_PASSWORD

## 4. Test the Setup

Push any change to the main branch to trigger the GitHub Actions workflow and verify everything works.

## Alternative: Use GitHub CLI

If you have GitHub CLI installed and authenticated:

```bash
# Set secrets using environment variables
export AZURE_CREDENTIALS='{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}'
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export TERRAFORM_STORAGE_ACCOUNT="tfstorage123456789"
export GRAFANA_ADMIN_PASSWORD="your-secure-password"

# Set the secrets
echo "$AZURE_CREDENTIALS" | gh secret set AZURE_CREDENTIALS
echo "$AZURE_SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID  
echo "$TERRAFORM_STORAGE_ACCOUNT" | gh secret set TERRAFORM_STORAGE_ACCOUNT
echo "tfstate-rg" | gh secret set TERRAFORM_STATE_RG
echo "$GRAFANA_ADMIN_PASSWORD" | gh secret set GRAFANA_ADMIN_PASSWORD
```

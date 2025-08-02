#!/usr/bin/env bash
set -euo pipefail

# ---- Config (edit as needed) -------------------------------------------------
SUBSCRIPTION_ID="${AZ_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
LOCATION="${LOCATION:-switzerlandnorth}"
SUFFIX="${SUFFIX:-26698}"   # storage account must be globally unique, lowercase
STATE_RG="tfstate-rg"
STATE_SA="tfstorage${SUFFIX}"
STATE_CONTAINER="state"
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/envs/azure/dev" && pwd)"
KUBECONFIG_OUT="${ENV_DIR}/kubeconfig"

# ---- Checks ------------------------------------------------------------------
command -v az >/dev/null || { echo "Azure CLI not found"; exit 1; }
command -v terraform >/dev/null || { echo "Terraform not found"; exit 1; }

echo "Using subscription: ${SUBSCRIPTION_ID}"
az account set --subscription "${SUBSCRIPTION_ID}"

# ---- 1) Bootstrap remote backend --------------------------------------------
echo ">> Creating remote state RG/SA/container if missing..."
az group create -n "${STATE_RG}" -l "${LOCATION}" >/dev/null

# Storage account names: 3-24 chars, lowercase letters/numbers only
if ! az storage account show -n "${STATE_SA}" -g "${STATE_RG}" >/dev/null 2>&1; then
  az storage account create \
    -n "${STATE_SA}" -g "${STATE_RG}" -l "${LOCATION}" \
    --sku Standard_LRS --kind StorageV2 --encryption-services blob >/dev/null
fi

az storage container create \
  --account-name "${STATE_SA}" --name "${STATE_CONTAINER}" >/dev/null

# ---- 2) Apply infra (whatever is enabled via tfvars) -------------------------
pushd "${ENV_DIR}" >/dev/null
  echo ">> terraform init"
  terraform init -upgrade

  echo ">> terraform apply (this may take several minutes)..."
  terraform apply -auto-approve

  echo ">> Writing kubeconfig"
  terraform output -raw kubeconfig > "${KUBECONFIG_OUT}"
popd >/dev/null

# ---- 3) Export kubeconfig for this shell session -----------------------------
echo "export KUBECONFIG=${KUBECONFIG_OUT}"
export KUBECONFIG="${KUBECONFIG_OUT}"

# ---- 4) Smoke tests ----------------------------------------------------------
echo ">> kubectl get nodes"
kubectl get nodes -o wide

echo "Bootstrap complete."
echo "Next: enable features in terraform.tfvars and re-run this script."
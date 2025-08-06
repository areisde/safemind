#!/usr/bin/env bash
set -euo pipefail

# Build images
echo "🔨  Building guard-rail image…"
docker build -t guardrail:dev services/guardrail

echo "🔨  Building llm-proxy image…"
docker build -t llm-proxy:dev services/llm-proxy

# Load into your local kind cluster
KIND_CLUSTER=${KIND_CLUSTER:-llm}        # default cluster name “dev”
echo "📦  Loading images into kind cluster \"$KIND_CLUSTER\" …"
kind load docker-image guardrail:dev   --name "$KIND_CLUSTER"
kind load docker-image llm-proxy:dev   --name "$KIND_CLUSTER"

# Trigger rolling restart so new images are pulled
echo "♻️  Restarting deployments…"
kubectl -n llm rollout restart deploy/guardrail
kubectl -n llm rollout restart deploy/llm-proxy
kubectl -n llm rollout status deploy/guardrail  --timeout=120s
kubectl -n llm rollout status deploy/llm-proxy  --timeout=120s
echo "✅  Images built, loaded and pods restarted."
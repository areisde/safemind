#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up MLOps Logging Dashboard..."

# Apply enhanced Promtail configuration
echo "📊 Updating Promtail configuration..."
kubectl apply -f observability/promtail-enhanced.yaml

# Wait for Promtail to be ready
echo "⏳ Waiting for Promtail to be ready..."
kubectl rollout status daemonset/promtail -n observability --timeout=60s

# Apply Grafana datasources (if not already configured via helm values)
echo "🔗 Configuring Grafana datasources..."
kubectl apply -f observability/grafana-datasources.yaml

# Apply MLOps dashboard
echo "📈 Installing MLOps dashboard..."
kubectl apply -f observability/grafana-mlops-dashboard.yaml

# Restart Grafana to pick up new configurations
echo "🔄 Restarting Grafana..."
kubectl rollout restart deployment/kps-grafana -n observability
kubectl rollout status deployment/kps-grafana -n observability --timeout=60s

echo "✅ Setup complete!"
echo ""
echo "🎯 Access your logging dashboard:"
echo "1. Grafana: http://localhost:3000"
echo "   - Username: admin"
echo "   - Password: prom-operator"
echo ""
echo "2. Loki (direct): http://localhost:3100"
echo ""
echo "📊 Available dashboards in Grafana:"
echo "- MLOps Services Logs (custom dashboard for your services)"
echo "- Kubernetes / Compute Resources / Namespace (Pods)"
echo "- Kubernetes / Compute Resources / Pod"
echo ""
echo "🔍 Example LogQL queries for your services:"
echo '- Guardrail logs: {namespace="llm", app="guardrail"}'
echo '- LLM-Proxy logs: {namespace="llm", app="llm-proxy"}'
echo '- Kong logs: {namespace="llm", app="kong"}'
echo '- Error logs only: {namespace="llm"} |~ "(?i)(error|exception|failed|fatal)"'
echo '- Last 100 lines: {namespace="llm", app="guardrail"} | tail 100'
echo ""
echo "🐛 Debug CrashLoopBackOff guardrail pod:"
echo "kubectl logs -n llm guardrail-64d74dd4c5-fw96t --previous"

#!/usr/bin/env bash
set -euo pipefail

echo "🧠 Setting up LLM Analytics Dashboard..."

# Apply LLM-specific dashboard
echo "📈 Installing LLM Analytics dashboard..."
kubectl apply -f observability/grafana-llm-analytics-dashboard.yaml

# Apply enhanced Promtail for LLM metrics
echo "📊 Deploying LLM-enhanced Promtail..."
kubectl apply -f observability/promtail-llm-enhanced.yaml

# Wait for Promtail to be ready
echo "⏳ Waiting for LLM Promtail to be ready..."
kubectl rollout status daemonset/promtail-llm -n observability --timeout=60s

# Restart Grafana to pick up new dashboard
echo "🔄 Restarting Grafana to load new dashboard..."
kubectl rollout restart deployment/kps-grafana -n observability
kubectl rollout status deployment/kps-grafana -n observability --timeout=60s

echo "✅ LLM Analytics setup complete!"
echo ""
echo "🎯 Access your LLM Analytics:"
echo "1. Grafana: http://localhost:3000"
echo "   - Username: admin"
echo "   - Password: prom-operator"
echo "   - Look for 'LLM Analytics & Metrics' dashboard"
echo ""
echo "📊 LLM Metrics Tracked:"
echo "- 🏷️  Token usage (input/output/total)"
echo "- ⚡ Energy consumption (kWh)"
echo "- 💰 Cost tracking (USD)"
echo "- ⏱️  Processing time"
echo "- 🤖 Model usage distribution"
echo "- 📈 Request rate and error rate"
echo "- 🔍 Structured log search"
echo ""
echo "🧪 Test your LLM proxy:"
echo 'curl -X POST http://localhost:8000/chat \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"prompt": "Hello, how are you?", "model": "gpt-4", "max_tokens": 100, "temperature": 0.7}'"'"
echo ""
echo "📝 Example LogQL queries for LLM metrics:"
echo '- All LLM requests: {namespace="llm", app="llm-proxy"} |= "llm_request_completed"'
echo '- High token usage: {namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | total_tokens > 1000'
echo '- Expensive requests: {namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | cost_usd > 0.10'
echo '- Slow requests: {namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | processing_time_seconds > 2'
echo '- GPT-4 usage: {namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | model = "gpt-4"'

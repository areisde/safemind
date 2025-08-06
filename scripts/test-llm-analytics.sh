#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Testing LLM Analytics with sample requests..."

# Get the LLM-proxy service endpoint
LLM_PROXY_URL="http://localhost:8000"

# Check if port-forward is needed
if ! curl -s "$LLM_PROXY_URL/healthz" > /dev/null 2>&1; then
  echo "🔗 Port-forwarding LLM-proxy service..."
  kubectl port-forward -n llm svc/llm-proxy 8000:8000 &
  PORT_FORWARD_PID=$!
  sleep 3
fi

echo "📊 Generating test LLM requests with different parameters..."

# Test different models and parameters
curl -X POST "$LLM_PROXY_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Write a short poem about artificial intelligence", "model": "gpt-4", "max_tokens": 150, "temperature": 0.8}'

sleep 1

curl -X POST "$LLM_PROXY_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Explain quantum computing in simple terms", "model": "gpt-3.5-turbo", "max_tokens": 200, "temperature": 0.3}'

sleep 1

curl -X POST "$LLM_PROXY_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Generate a detailed technical analysis of machine learning algorithms for natural language processing", "model": "gpt-4", "max_tokens": 500, "temperature": 0.1}'

sleep 1

curl -X POST "$LLM_PROXY_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello!", "model": "gpt-3.5-turbo", "max_tokens": 50, "temperature": 1.0}'

echo ""
echo "✅ Test requests completed!"
echo ""
echo "📈 Check your LLM Analytics dashboard at: http://localhost:3000"
echo "🔍 Look for the 'LLM Analytics & Metrics' dashboard"
echo ""
echo "📊 You should see:"
echo "- Token usage metrics"
echo "- Energy consumption data"
echo "- Cost analysis"
echo "- Processing time trends"
echo "- Model usage distribution"

# Clean up port-forward if we started it
if [ -n "${PORT_FORWARD_PID:-}" ]; then
  echo "🧹 Cleaning up port-forward..."
  kill $PORT_FORWARD_PID 2>/dev/null || true
fi

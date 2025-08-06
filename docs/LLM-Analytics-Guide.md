# 🧠 LLM Analytics & Custom Logging System

## 🎯 Overview

I've created a complete LLM analytics system that allows you to log custom metrics from your LLM-proxy service and visualize them in a dedicated Grafana dashboard. This system tracks:

- **Token usage** (input/output/total)
- **Energy consumption** (kWh estimates)
- **Cost tracking** (USD)
- **Processing time** 
- **Model usage distribution**
- **Request rates and error rates**

## 📊 What's Been Implemented

### 1. Enhanced LLM-Proxy Service
**File:** `services/llm-proxy/app/main.py`

**Key Features:**
- **Structured JSON logging** using `structlog` and `python-json-logger`
- **Comprehensive metrics tracking** for every request
- **Token estimation** and cost calculation
- **Energy consumption estimation**
- **Request ID tracking** for correlation
- **Error handling** with detailed logging

**Sample Log Output:**
```json
{
  "timestamp": "2025-08-06T10:30:15.123Z",
  "logger_name": "llm-metrics",
  "level": "INFO",
  "event": "llm_request_completed",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "model": "gpt-4",
  "input_tokens": 25,
  "output_tokens": 150,
  "total_tokens": 175,
  "processing_time_seconds": 2.345,
  "energy_consumption_kwh": 0.000875,
  "cost_usd": 0.0105,
  "temperature": 0.7,
  "status": "success"
}
```

### 2. Custom Grafana Dashboard
**File:** `observability/grafana-llm-analytics-dashboard.yaml`

**Dashboard Panels:**
- **Request Rate** - Real-time request per second
- **Token Usage** - Total tokens consumed
- **Energy Consumption** - kWh tracking
- **Cost Tracking** - USD spent
- **Processing Time** - Response latency
- **Model Distribution** - Usage by AI model
- **Error Rate** - Success/failure tracking
- **Structured Log Viewer** - Searchable logs

### 3. Enhanced Log Collection
**File:** `observability/promtail-llm-enhanced.yaml`

**Features:**
- **JSON log parsing** with automatic field extraction
- **Label enrichment** for better querying
- **LLM-specific filtering** and processing
- **Metrics extraction** for dashboard visualization

## 🔧 How to Use

### Step 1: Deploy the Updated System
```bash
# Deploy LLM analytics
./scripts/setup-llm-analytics.sh

# Rebuild your LLM-proxy with new dependencies
# (You'll need to rebuild the Docker container with the updated requirements.txt)
```

### Step 2: Access Your Dashboards
- **Grafana:** http://localhost:3000
  - Username: `admin`
  - Password: `prom-operator`
- **Look for:** "LLM Analytics & Metrics" dashboard

### Step 3: Generate Test Data
```bash
# Run test requests to generate sample data
./scripts/test-llm-analytics.sh
```

### Step 4: Explore Your Data

**Useful LogQL Queries:**
```logql
# All LLM requests
{namespace="llm", app="llm-proxy"} |= "llm_request_completed"

# High token usage (>1000 tokens)
{namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | total_tokens > 1000

# Expensive requests (>$0.10)
{namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | cost_usd > 0.10

# Slow requests (>2 seconds)
{namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | processing_time_seconds > 2

# GPT-4 specific usage
{namespace="llm", app="llm-proxy"} |= "llm_request_completed" | json | model = "gpt-4"

# Error analysis
{namespace="llm", app="llm-proxy"} |= "llm_request_failed"
```

## 📈 Custom Metrics You Can Add

The system is designed to be extensible. You can easily add more metrics:

### Example: Add User Tracking
```python
# In your LLM-proxy
metrics_logger.info("llm_request_completed", 
    request_id=request_id,
    # ... existing metrics ...
    user_id=req.user_id,  # Add user tracking
    organization=req.organization,  # Add org tracking
    prompt_category="creative_writing",  # Add categorization
    # ... more custom fields
)
```

### Example: Add Performance Metrics
```python
# Add more detailed performance tracking
metrics_logger.info("llm_request_completed", 
    # ... existing metrics ...
    queue_time_seconds=queue_time,
    model_inference_time=inference_time,
    network_latency=network_time,
    cache_hit=cache_was_used,
)
```

## 🚀 Cloud Deployment Strategy

### For Azure Deployment:
1. **Enable observability** in terraform.tfvars:
   ```terraform
   enable_observability = true
   ```

2. **Use Azure Container Insights** alongside Loki/Grafana
3. **Deploy same configurations** via Helm or kubectl
4. **Connect to Azure Log Analytics** for long-term storage

### Files Ready for Cloud:
- `observability/grafana-llm-analytics-dashboard.yaml`
- `observability/promtail-llm-enhanced.yaml` 
- `observability/grafana-datasources.yaml`

## 🎛️ Configuration Options

### Energy Consumption Rates
Update energy rates in `main.py`:
```python
energy_rates = {
    "gpt-4": 0.005,  # kWh per 1000 tokens
    "gpt-3.5-turbo": 0.002,
    "gpt-4-turbo": 0.004,
    "custom-model": 0.003,  # Add your models
}
```

### Cost Tracking
Update pricing in `main.py`:
```python
pricing = {
    "gpt-4": {"input": 0.03, "output": 0.06},  # USD per 1k tokens
    "gpt-3.5-turbo": {"input": 0.0015, "output": 0.002},
    "your-model": {"input": 0.01, "output": 0.02},
}
```

## 🔍 Troubleshooting

### Common Issues:

1. **No data in dashboard:**
   - Check if LLM-proxy pods have the updated code
   - Verify Promtail is collecting logs: `kubectl logs -n observability promtail-llm-xxx`
   - Test LogQL queries in Grafana Explore

2. **Dashboard not showing:**
   - Restart Grafana: `kubectl rollout restart deployment/kps-grafana -n observability`
   - Check ConfigMaps: `kubectl get cm -n observability`

3. **Logs not parsing:**
   - Verify JSON format in LLM-proxy logs
   - Check Promtail configuration in `promtail-llm-config`

## 📊 Business Value

This system provides:
- **Cost optimization** through detailed usage tracking
- **Performance monitoring** for SLA compliance  
- **Energy consumption** insights for sustainability
- **User behavior** analysis through request patterns
- **Model comparison** for cost/performance optimization
- **Operational visibility** for debugging and monitoring

## 🔮 Next Steps

1. **Rebuild and deploy** updated LLM-proxy
2. **Customize metrics** for your specific use case
3. **Set up alerts** based on thresholds (cost, latency, errors)
4. **Export dashboards** for production deployment
5. **Integrate with business metrics** for ROI analysis

Your logging system is now enterprise-ready with full LLM analytics! 🎉

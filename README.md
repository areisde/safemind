# MLOps Platform

A comprehensive MLOps platform built on Kubernetes with observability, LLM analytics, and automated deployment.

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd mlops

# 2. Run automated setup (requires Azure CLI, Terraform, kubectl, Helm)
./scripts/setup-deployment.sh

# 3. Access services
./scripts/open-dashboards.sh
```

## 📋 What You Get

- **🔍 Observability Stack**: Prometheus, Grafana, Loki with custom dashboards
- **🤖 LLM Analytics**: Token usage, cost tracking, energy consumption metrics
- **🛡️ Security**: Network policies, rate limiting, request size controls
- **📊 Monitoring**: Custom Grafana dashboards for MLOps metrics
- **🔄 CI/CD Ready**: GitHub Actions workflows for automated deployment

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kong Gateway  │────│   LLM Proxy     │────│   Guardrail     │
│   (Ingress)     │    │   (FastAPI)     │    │   (FastAPI)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────────┐
         │              Observability Stack                    │
         │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
         │  │ Prometheus  │ │   Grafana   │ │    Loki     │   │
         │  │ (Metrics)   │ │(Dashboards) │ │   (Logs)    │   │
         │  └─────────────┘ └─────────────┘ └─────────────┘   │
         └─────────────────────────────────────────────────────┘
```

## 📚 Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete setup instructions
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design and components
- **[API Documentation](docs/API.md)** - Service endpoints and usage

## 🛠️ Services

| Service | Purpose | Port | Metrics |
|---------|---------|------|---------|
| Kong Gateway | API Gateway & Ingress | 80/443 | Request routing, rate limiting |
| LLM Proxy | LLM request handling | 8001 | Token usage, cost, energy |
| Guardrail | Safety & compliance | 8002 | Request validation, filtering |
| Grafana | Dashboards & Visualization | 3000 | admin/prom-operator |
| Prometheus | Metrics collection | 9090 | System metrics |
| Loki | Log aggregation | 3100 | Centralized logging |

## 🔧 Development

### Local Development
```bash
# Start local services
docker-compose up -d

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/
```

### Adding New Services
1. Create Helm chart in `charts/`
2. Add observability configuration
3. Update deployment scripts
4. Add tests in `tests/`

## 🔐 Security

- Secrets managed via Azure Key Vault
- Network policies for east-west traffic
- Rate limiting and request size controls
- TLS termination at gateway
- RBAC for Kubernetes access

## 📊 Monitoring & Observability

### Custom Dashboards
- **MLOps Overview**: Service health, request rates, error rates
- **LLM Analytics**: Token usage, cost analysis, energy consumption
- **Infrastructure**: Kubernetes cluster metrics, resource usage

### Alerts (Production)
- High error rates
- Resource exhaustion
- Service downtime
- Cost thresholds exceeded

## 🚀 Deployment Environments

### Development
- Single-node cluster
- Basic monitoring
- Local storage

### Production
- Multi-node with auto-scaling
- Advanced monitoring & alerting
- Persistent storage with backup
- Network policies

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Submit pull request

## 📝 License

[Your License Here]

## 🆘 Support

- 📖 Check the [troubleshooting guide](docs/DEPLOYMENT.md#troubleshooting)
- 🐛 [Open an issue](https://github.com/your-org/mlops/issues)
- 💬 [Discussions](https://github.com/your-org/mlops/discussions)
# Trigger new build to resolve GHCR permissions

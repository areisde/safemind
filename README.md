# SafeMind

SafeMind is a comprehensive, production-ready MLOps platform designed for safe and responsible LLM operations. Built on Kubernetes, it provides enterprise-grade observability, security guardrails, and automated deployment for AI/ML workloads with a focus on LLM safety, compliance, and cost optimization.

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/areisde/safemind.git
cd safemind

# 2. Run automated setup (requires Azure CLI, Terraform, kubectl, Helm)
./scripts/setup-deployment.sh

# 3. Access services
./scripts/open-dashboards.sh
```

## 📋 What You Get

- **🔍 Observability Stack**: Prometheus, Grafana, Loki with custom dashboards
- **🤖 LLM Analytics**: Token usage, cost tracking, energy consumption metrics
- **🛡️ Security Guardrails**: AI safety controls, content filtering, and compliance monitoring
- **📊 Monitoring**: Custom Grafana dashboards for MLOps and LLM metrics
- **🔄 CI/CD Ready**: GitHub Actions workflows for automated deployment
- **💰 Cost Optimization**: Real-time cost tracking and budget alerts for LLM usage
- **⚡ Energy Tracking**: Environmental impact monitoring for sustainable AI operations

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kong Gateway  │────│   LLM Proxy     │────│   Guardrail     │
│   (Ingress)     │    │   (Analytics)   │    │   (AI Safety)   │
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
| LLM Proxy | LLM request handling & analytics | 8001 | Token usage, cost, energy |
| Guardrail | AI safety & compliance | 8002 | Request validation, content filtering |
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

## 🔐 Security & Compliance

- **AI Safety Guardrails**: Content filtering, prompt injection detection, and response validation
- **Azure Key Vault Integration**: Secure secrets management for LLM API keys
- **Network Policies**: East-west traffic security within the Kubernetes cluster
- **Rate Limiting & Request Controls**: Prevent abuse and manage API costs
- **TLS Termination**: End-to-end encryption for all communications
- **RBAC**: Role-based access control for Kubernetes resources
- **Audit Logging**: Comprehensive logging for compliance and security monitoring

## 📊 Monitoring & Observability

### Custom Dashboards
- **SafeMind Overview**: Service health, request rates, error rates
- **LLM Analytics**: Token usage, cost analysis, energy consumption
- **AI Safety Metrics**: Guardrail effectiveness, content filtering stats
- **Infrastructure**: Kubernetes cluster metrics, resource usage
- **Cost Management**: Real-time spend tracking and budget alerts

### Alerts (Production)
- High error rates and service downtime
- Resource exhaustion and scaling events
- Cost thresholds exceeded for LLM usage
- AI safety violations and guardrail triggers
- Security policy violations

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

MIT License - See [LICENSE](LICENSE) file for details

## 🆘 Support

- 📖 Check the [troubleshooting guide](docs/DEPLOYMENT.md#troubleshooting)
- 🐛 [Open an issue](https://github.com/areisde/safemind/issues)
- 💬 [Discussions](https://github.com/areisde/safemind/discussions)

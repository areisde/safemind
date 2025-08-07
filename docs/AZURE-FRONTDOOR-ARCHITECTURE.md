# Azure Front Door + WAF Detailed Architecture
# Enterprise-grade security without user authentication friction

## Architecture Overview
```
[Business Users] → [Azure Front Door] → [WAF Rules] → [agent.reisdematos.ch] → [Kong Gateway] → [AI Services]
     ↓                    ↓                ↓              ↓                    ↓              ↓
  No Auth Required    Geo-filtering    IP Whitelisting   Rate Limiting    Content Filter   Azure OpenAI
                      DDoS Protection   Bot Protection    Security Headers  Guardrails      LLM Proxy
```

## Security Layers

### Layer 1: Azure Front Door (Edge Security)
- **Global DDoS Protection**: Up to 100 Gbps automatic mitigation
- **SSL Termination**: Managed certificates, TLS 1.3
- **Geo-blocking**: Block countries/regions you don't operate in
- **Bot Detection**: AI-powered bot filtering
- **Caching**: Reduce load on your AKS cluster

### Layer 2: Web Application Firewall (WAF)
- **IP Whitelisting**: Only allow trusted networks
- **Rate Limiting**: Prevent abuse (per-IP, per-session)
- **OWASP Top 10 Protection**: SQL injection, XSS, etc.
- **Custom Rules**: Block suspicious patterns
- **Managed Rule Sets**: Microsoft threat intelligence

### Layer 3: Your Existing Kong Gateway
- **Content Filtering**: Your guardrail service
- **Internal Rate Limiting**: Additional protection
- **Health Checks**: Ensure services are healthy
- **Routing Logic**: Direct traffic to appropriate services

## Use Case Scenarios

### Use Case 1: Business Team Demo/Testing
**Who**: Sales team, executives, business analysts
**Access Pattern**: Web browser from office/home
**Security**: IP-based (office) + device certificates (remote)

```yaml
# WAF Rule for Business Users
BusinessUserAccess:
  Priority: 100
  Conditions:
    - IP: "OFFICE_IP_RANGE/24"
    - UserAgent: "Contains 'Mozilla'" # Web browsers
    - Geography: "Switzerland, Germany, US"
  Action: Allow
  RateLimit: "100 requests/hour per IP"
```

### Use Case 2: Frontend Application Integration
**Who**: Customer-facing web app, mobile app
**Access Pattern**: Server-to-server API calls
**Security**: Application IP whitelisting + request patterns

```yaml
# WAF Rule for Frontend Apps
FrontendAppAccess:
  Priority: 200
  Conditions:
    - IP: "FRONTEND_SERVER_IPS"
    - Headers: "X-App-Name: reisdematos-frontend"
    - Method: "POST"
    - Path: "/chat, /sanitize"
  Action: Allow
  RateLimit: "1000 requests/hour per IP"
```

### Use Case 3: Partner/Client Access
**Who**: Trusted partners, enterprise clients
**Access Pattern**: Their applications calling your AI services
**Security**: Partner IP ranges + usage quotas

```yaml
# WAF Rule for Partners
PartnerAccess:
  Priority: 300
  Conditions:
    - IP: "PARTNER_IP_RANGES"
    - Headers: "X-Partner-ID: {partner-uuid}"
  Action: Allow
  RateLimit: "500 requests/day per partner"
  Custom: "Log all requests for billing"
```

### Use Case 4: Emergency/Maintenance Access
**Who**: IT team, developers
**Access Pattern**: Direct API access for debugging
**Security**: VPN + MFA + temporary access

```yaml
# WAF Rule for Emergency Access
EmergencyAccess:
  Priority: 50
  Conditions:
    - IP: "VPN_GATEWAY_IP"
    - Headers: "X-Emergency-Token: {rotating-token}"
    - TimeWindow: "Only during maintenance windows"
  Action: Allow
  RateLimit: "Unlimited for 2 hours"
```

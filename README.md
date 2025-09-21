<!-- markdownlint-disable MD041 -->
<p align="center">
  <img width="360" src="https://raw.githubusercontent.com/titaniumlabsoss/helm-charts/refs/heads/main/assets/titanium-labs-logo.png" alt="Titanium Labs Logo" />
</p>

<p align="center">
  <a href="https://github.com/titaniumlabsoss/helm-charts"><img src="https://badgen.net/github/stars/titaniumlabsoss/helm-charts?icon=github" /></a>
  <a href="https://github.com/titaniumlabsoss/helm-charts"><img src="https://badgen.net/github/forks/titaniumlabsoss/helm-charts?icon=github" /></a>
  <a href="https://github.com/titaniumlabsoss/helm-charts/security"><img src="https://img.shields.io/github/issues-search/titaniumlabsoss/helm-charts?query=is%3Aopen%20is%3Aissue%20label%3Asecurity&label=security%20issues" /></a>
  <a href="https://artifacthub.io/packages/search?user=titaniumlabs"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/titaniumlabs" /></a>
  <a href="https://github.com/titaniumlabsoss/helm-charts/blob/main/LICENSE"><img src="https://badgen.net/badge/license/Apache-2.0/blue" /></a>
</p>

# Titanium Labs - Helm Charts

**Production-grade, security-focused Helm charts**. Designed with *security best practices*, compliance standards, and enterprise deployment patterns at the core.

Built for enterprises where trust, discipline, and resilience are non-negotiable.

## Why Security-Focused Helm Charts?

Most Helm charts prioritize ease of deployment. We prioritize **security and compliance**.

Every Titanium Labs Helm chart is crafted with:

- **Security by default** — secure configurations out of the box
- **Least privilege** — minimal RBAC permissions and capabilities
- **Network isolation** — NetworkPolicies and service mesh ready
- **Secret management** — integrated with external secret operators
- **Compliance-ready** — SOC2, HIPAA, CIS, NIST and DISA STIG benchmarks

## Security Architecture

### Security at the Core
- Secure defaults for all deployments
- Pod Security Standards enforcement
- Network segmentation with NetworkPolicies
- Non-root containers with read-only filesystems
- Resource limits and quotas

### Compliance Features
- Built-in security contexts and policies
- Audit logging and monitoring integration
- Secret rotation and management
- Vulnerability scanning integration
- RBAC with minimal permissions

### Enterprise Patterns
- Multi-tenancy support
- High availability configurations
- Disaster recovery patterns
- Observability and monitoring
- GitOps and CI/CD integration

## Methodology

We follow a **secure-by-design** philosophy, applied with precision:

- Chart linting and security scanning in CI/CD
- Kubernetes security best practices validation
- Supply chain security with signed charts
- Automated testing against multiple Kubernetes versions

## Getting Started

Add the Titanium Labs Helm repository:

```bash
helm repo add titaniumlabs https://charts.titaniumlabs.io
helm repo update
```

Install a chart with secure defaults:

```bash
helm install my-app titaniumlabs/APP
```

Install with custom security configuration:

```bash
helm install my-app titaniumlabs/APP \
  --set securityContext.runAsNonRoot=true \
  --set networkPolicy.enabled=true \
  --set podSecurityContext.fsGroup=2000
```

Chart Versions
- latest — latest stable release
- [version] — specific semantic version (e.g., 1.2.3)
- [version]-rc — release candidate versions

## Contributing

We welcome contributions with the same discipline we apply to security. Please read the Contributing Guide.

```bash
git clone https://github.com/titaniumlabsoss/helm-charts.git
cd helm-charts
helm lint charts/APP
helm template charts/APP | kubectl apply --dry-run=client -f -
```

## Security Disclosure

If you discover a vulnerability, do not open a public issue. Please email us at: `security@titaniumlabs.io`

<p align="center">
  <strong>Titanium Labs</strong> · Forging the future of cybersecurity with open-source precision.
</p>

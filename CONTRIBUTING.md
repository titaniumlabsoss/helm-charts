# Contributing Guidelines

Thank you for your interest in contributing to Titanium Labs' Helm Charts project! We welcome contributions from the community to help build more secure Kubernetes deployments.

## Ways to Contribute

- **New Helm charts** for popular applications
- **Security improvements** to existing charts
- **Documentation** enhancements
- **Bug reports** and vulnerability disclosures
- **Feature requests** and discussions
- **Testing** and validation of charts

## Getting Started

### Prerequisites

- [Helm](https://helm.sh/) v3.8+ installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured with cluster access
- Git for version control
- [helm-unittest](https://github.com/helm-unittest/helm-unittest) for testing
- Basic understanding of Kubernetes and Helm chart development

### Development Setup

1. **Fork and clone the repository**

```bash
git clone git@github.com:titaniumlabsoss/helm-charts.git
cd helm-charts
```

2. **Create a feature branch**

```bash
git checkout -b feature/add-mongodb-chart
```

3. **Set up development tools**

```bash
# Install helm-unittest for testing
helm plugin install https://github.com/helm-unittest/helm-unittest

# Install chart-testing for linting and testing
pip install chart-testing

# Install kubeval for Kubernetes manifest validation
curl -L https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz | tar xz
sudo mv kubeval /usr/local/bin
```

## Adding New Charts

### Directory Structure

Each chart should follow this structure:

```
charts/
├── postgres/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── podsecuritypolicy.yaml
│   │   └── rbac.yaml
│   ├── tests/
│   │   ├── deployment_test.yaml
│   │   ├── security_test.yaml
│   │   └── values_test.yaml
│   └── security/
│       ├── security-checklist.md
│       └── compliance-notes.md
├── nginx/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── tests/
└── redis/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    └── tests/
```

### Chart Requirements

#### Security Requirements (MANDATORY)

- **Pod Security Standards**: Charts must enforce restricted security standards
- **Non-root containers**: All containers must run as unprivileged users
- **Read-only root filesystems**: Containers should use read-only root filesystems
- **NetworkPolicies**: Include network isolation policies
- **RBAC**: Implement least-privilege access controls
- **Resource limits**: Define CPU and memory limits for all containers

#### Documentation Requirements

- **Chart README**: Usage instructions and security features
- **Security checklist**: Document all security measures applied
- **Values documentation**: Comprehensive values.yaml documentation
- **Example configurations**: Multiple deployment scenarios

#### Testing Requirements

- **Security tests**: Automated security validation with helm-unittest
- **Functionality tests**: Ensure chart renders and deploys correctly
- **Validation tests**: Template validation and Kubernetes API compliance

## Security Review Process

### Before Submitting

1. **Lint and validate chart**

```bash
helm lint charts/myapp
helm template charts/myapp | kubeval
```

2. **Run security tests**

```bash
# Run helm unit tests
helm unittest charts/myapp

# Validate security contexts
helm template charts/myapp | grep -A 10 securityContext
```

3. **Test functionality**

```bash
# Test chart installation
helm install test-release charts/myapp --dry-run --debug
helm install test-release charts/myapp
helm test test-release
```

### Security Checklist

- [ ] Containers run as non-root users by default (runAsNonRoot: true)
- [ ] Read-only root filesystem enabled where possible
- [ ] NetworkPolicy templates included and functional
- [ ] RBAC with minimal permissions implemented
- [ ] Resource limits defined for all containers
- [ ] Security contexts properly configured
- [ ] Secrets properly managed (no hardcoded values)
- [ ] Health checks implemented
- [ ] Security tests pass
- [ ] Documentation complete

## Pull Request Process

### 1. **Before Creating PR**

- Ensure all tests pass
- Update documentation
- Follow commit message conventions
- Rebase on latest main branch

### 2. **PR Description Template**

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New Helm chart
- [ ] Security improvement to existing chart
- [ ] Documentation update
- [ ] Bug fix

## Security Review
- [ ] Chart linting passes
- [ ] Containers run as non-root users
- [ ] NetworkPolicies implemented
- [ ] RBAC follows least privilege
- [ ] Security tests pass
- [ ] Security checklist completed

## Testing
- [ ] Chart renders correctly
- [ ] helm unittest tests pass
- [ ] Manual deployment testing completed
- [ ] Upgrade/rollback testing completed

## Documentation
- [ ] Chart README updated
- [ ] values.yaml documented
- [ ] Security checklist completed
- [ ] Example configurations provided
```

### 3. **Review Process**

1. **Automated checks**: CI/CD pipeline runs chart linting and security validation
2. **Security review**: Titanium Labs team reviews security configurations
3. **Code review**: Community and maintainer review
4. **Final approval**: Two approvals required for merge

## Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead, email: **security@titaniumlabs.io**

Include:
- Chart name and version
- Vulnerability details
- Steps to reproduce
- Potential impact assessment

We aim to respond within 24 hours and provide fixes within 7 days for critical issues.

## Documentation Standards

### README Structure for Charts

```markdown
# Application Name

Brief description of the Helm chart

## Prerequisites
## Installation
## Configuration
## Security Features
## Upgrade/Rollback
## Troubleshooting
## Values
```

### Commit Message Format

```
type(scope): description

Examples:
feat(postgres): add PostgreSQL 16 Helm chart
fix(nginx): resolve RBAC permissions
docs(redis): update security configuration guide
```

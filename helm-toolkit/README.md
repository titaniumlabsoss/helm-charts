# Helm Toolkit

A comprehensive Helm library chart that provides common template helpers and utilities for Titanium Labs Helm charts. This library combines the best practices from Bitnami common chart and OpenStack helm-toolkit to provide a robust set of reusable components.

## Overview

This is a **library chart** that provides template helpers and utilities to other charts. It cannot be deployed directly and must be used as a dependency in other Helm charts.

## Usage

### Adding as a Dependency

Add the helm-toolkit as a dependency in your chart's `Chart.yaml`:

```yaml
dependencies:
- name: helm-toolkit
  version: "1.0.0"
  repository: "file://../helm-toolkit"
```

Then run:
```bash
helm dependency update
```

### Important Notes

- This is a **library chart only** - it contains no values.yaml file
- All configuration must be provided by the consuming chart
- Template helpers expect configuration to be passed via the `context` parameter

### Basic Usage in Templates

```yaml
# In your deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm-toolkit.fullname" . }}
  labels:
    {{- include "helm-toolkit.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "helm-toolkit.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "helm-toolkit.selectorLabels" . | nindent 8 }}
      annotations:
        {{- include "helm-toolkit.podAnnotations" . | nindent 8 }}
    spec:
      {{- include "helm-toolkit.podSecurityContext" (dict "context" .) | nindent 6 }}
      serviceAccountName: {{ include "helm-toolkit.serviceAccountName" (dict "context" .) }}
      containers:
      - name: app
        image: {{ include "helm-toolkit.image" .Values.image }}
        {{- include "helm-toolkit.securityContext" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.resources" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.livenessProbe" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.readinessProbe" (dict "context" .) | nindent 8 }}
```

## Available Template Helpers

### Core Helpers (`_labels.tpl`)

- `helm-toolkit.name`: Chart name
- `helm-toolkit.fullname`: Full application name
- `helm-toolkit.chart`: Chart name and version
- `helm-toolkit.labels`: Standard Kubernetes labels
- `helm-toolkit.selectorLabels`: Selector labels for workloads
- `helm-toolkit.componentLabels`: Component-specific labels
- `helm-toolkit.annotations`: Common annotations
- `helm-toolkit.podAnnotations`: Pod annotations with config checksums

### Resource Management (`_resources.tpl`)

- `helm-toolkit.resources`: Resource limits and requests
- `helm-toolkit.nodeSelector`: Node selector configuration
- `helm-toolkit.tolerations`: Pod tolerations
- `helm-toolkit.affinity`: Pod affinity rules
- `helm-toolkit.priorityClassName`: Priority class configuration
- `helm-toolkit.topologySpreadConstraints`: Topology spread constraints

### Security (`_security.tpl`)

- `helm-toolkit.podSecurityContext`: Pod security context
- `helm-toolkit.securityContext`: Container security context
- `helm-toolkit.podSecurityStandards`: Pod Security Standards annotations
- `helm-toolkit.podDisruptionBudget`: Pod disruption budget
- `helm-toolkit.networkSecurityPolicy`: Network security policy

### Service Account & RBAC (`_serviceaccount.tpl`)

- `helm-toolkit.serviceAccountName`: Service account name
- `helm-toolkit.serviceAccount`: Service account manifest
- `helm-toolkit.role`: RBAC Role manifest
- `helm-toolkit.roleBinding`: RBAC RoleBinding manifest
- `helm-toolkit.clusterRole`: RBAC ClusterRole manifest
- `helm-toolkit.clusterRoleBinding`: RBAC ClusterRoleBinding manifest

### Configuration (`_configmap.tpl`)

- `helm-toolkit.configMap`: ConfigMap manifest
- `helm-toolkit.secret`: Secret manifest
- `helm-toolkit.configMapVolume`: ConfigMap volume definition
- `helm-toolkit.secretVolume`: Secret volume definition
- `helm-toolkit.envFromConfigMap`: Environment variables from ConfigMap
- `helm-toolkit.envFromSecret`: Environment variables from Secret

### Networking (`_networking.tpl`)

- `helm-toolkit.service`: Service manifest
- `helm-toolkit.ingress`: Ingress manifest
- `helm-toolkit.networkPolicy`: NetworkPolicy manifest
- `helm-toolkit.serviceMonitor`: Prometheus ServiceMonitor manifest

### Database & Messaging (`_database.tpl`)

- `helm-toolkit.databaseUrl`: Database connection string
- `helm-toolkit.databaseMigrationJob`: Database migration job
- `helm-toolkit.postgresql`: PostgreSQL deployment
- `helm-toolkit.redis`: Redis deployment
- `helm-toolkit.messageQueueEnv`: Message queue environment variables

### Monitoring & Health (`_monitoring.tpl`)

- `helm-toolkit.livenessProbe`: Liveness probe configuration
- `helm-toolkit.readinessProbe`: Readiness probe configuration
- `helm-toolkit.startupProbe`: Startup probe configuration
- `helm-toolkit.metricsAnnotations`: Prometheus metrics annotations
- `helm-toolkit.loggingEnv`: Logging environment variables
- `helm-toolkit.telemetryEnv`: Telemetry environment variables
- `helm-toolkit.horizontalPodAutoscaler`: HPA manifest
- `helm-toolkit.prometheusRule`: PrometheusRule manifest

### Utilities (`_utils.tpl`)

- `helm-toolkit.merge`: Merge dictionaries
- `helm-toolkit.validateRequired`: Validate required values
- `helm-toolkit.randomString`: Generate random string
- `helm-toolkit.toSnakeCase`: Convert to snake_case
- `helm-toolkit.toKebabCase`: Convert to kebab-case
- `helm-toolkit.imagePullPolicy`: Smart image pull policy
- `helm-toolkit.image`: Format image reference
- `helm-toolkit.resourceProfile`: Predefined resource profiles
- `helm-toolkit.waitFor`: Wait for dependency script
- `helm-toolkit.initContainer`: Init container for dependencies
- `helm-toolkit.persistentVolumeClaim`: PVC manifest

## Component-Based Configuration

Many helpers support component-based configuration, allowing different settings for different parts of your application. Since this library chart has no values.yaml, all configuration comes from the consuming chart:

```yaml
# In your chart's values.yaml
resources:
  api:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  worker:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi

# In your templates
{{- include "helm-toolkit.resources" (dict "context" . "component" "api") }}
{{- include "helm-toolkit.resources" (dict "context" . "component" "worker") }}
```

## Security Best Practices

The toolkit enforces security best practices by default:

- Non-root containers (UID 65534)
- Read-only root filesystem
- Dropped capabilities
- seccomp profile enforcement
- Pod Security Standards compliance

## Resource Profiles

Use predefined resource profiles for consistent sizing:

```yaml
# Use predefined profile
{{- include "helm-toolkit.resourceProfile" (dict "profile" "small") | nindent 8 }}

# Override with custom values from your chart's values
{{- include "helm-toolkit.resourceProfile" (dict "profile" "medium" "custom" .Values.resources) | nindent 8 }}
```

Available profiles: `nano`, `micro`, `small`, `medium`, `large`, `xlarge`

## Examples

### Complete Application Deployment

```yaml
# templates/deployment.yaml
{{- include "helm-toolkit.serviceAccount" (dict "context" .) }}
{{- include "helm-toolkit.configMap" (dict "context" . "component" "app" "name" "app-config" "data" .Values.config) }}
{{- include "helm-toolkit.podDisruptionBudget" (dict "context" .) }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm-toolkit.fullname" . }}
  labels:
    {{- include "helm-toolkit.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      {{- include "helm-toolkit.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "helm-toolkit.selectorLabels" . | nindent 8 }}
      annotations:
        {{- include "helm-toolkit.podAnnotations" . | nindent 8 }}
        {{- include "helm-toolkit.metricsAnnotations" (dict "context" .) | nindent 8 }}
    spec:
      {{- include "helm-toolkit.podSecurityContext" (dict "context" .) | nindent 6 }}
      serviceAccountName: {{ include "helm-toolkit.serviceAccountName" (dict "context" .) }}
      {{- include "helm-toolkit.nodeSelector" (dict "context" .) | nindent 6 }}
      {{- include "helm-toolkit.tolerations" (dict "context" .) | nindent 6 }}
      {{- include "helm-toolkit.affinity" (dict "context" .) | nindent 6 }}
      containers:
      - name: app
        image: {{ include "helm-toolkit.image" .Values.image }}
        imagePullPolicy: {{ include "helm-toolkit.imagePullPolicy" .Values.image.tag }}
        {{- include "helm-toolkit.securityContext" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.resources" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.livenessProbe" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.readinessProbe" (dict "context" .) | nindent 8 }}
        env:
        {{- include "helm-toolkit.loggingEnv" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.telemetryEnv" (dict "context" .) | nindent 8 }}
        envFrom:
        {{- include "helm-toolkit.envFromConfigMap" (dict "configMapName" "app-config") | nindent 8 }}
```

### Service and Ingress

```yaml
# templates/service.yaml
{{- include "helm-toolkit.service" (dict "context" . "component" "app" "type" "ClusterIP" "ports" (list (dict "port" 80 "targetPort" 8080 "name" "http"))) }}

# templates/ingress.yaml
{{- if .Values.ingress.enabled }}
{{- include "helm-toolkit.ingress" (dict "context" . "component" "app" "className" .Values.ingress.className "hosts" .Values.ingress.hosts "tls" .Values.ingress.tls "annotations" .Values.ingress.annotations) }}
{{- end }}
```

## Example Values Files

This library chart includes comprehensive example values files to help you get started:

### `values-example.yaml`
A practical, production-ready configuration showing:
- Simple web application setup
- Multi-component applications (frontend, API, worker)
- Database deployment with persistence
- Environment-specific configurations

### `values-recommended.yaml`
A comprehensive reference showing all available configuration options:
- Complete security hardening
- Advanced networking and ingress
- Autoscaling and resource management
- Monitoring and observability
- Component-specific configurations
- Cloud provider integrations

### Usage Examples

**Single component application:**
```yaml
# Simple web app with database
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/MyAppRole"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  hosts:
  - host: myapp.example.com
    paths:
    - path: /
      pathType: Prefix
```

**Multi-component application:**
```yaml
# Different configurations per component
components:
  frontend:
    replicaCount: 3
    resources:
      limits: { cpu: 200m, memory: 256Mi }
    service: { port: 80, targetPort: 3000 }

  api:
    replicaCount: 2
    resources:
      limits: { cpu: 1000m, memory: 1Gi }
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 20

  worker:
    replicaCount: 1
    nodeSelector:
      workload-type: batch
    tolerations:
    - key: spot-instance
      effect: NoSchedule
```

**Production security hardening:**
```yaml
# Security-focused configuration
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 65534
  fsGroup: 65534
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]

networkPolicy:
  enabled: true
  policyTypes: ["Ingress", "Egress"]

podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

## Template Usage Patterns

### Basic Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm-toolkit.fullname" . }}
  labels:
    {{- include "helm-toolkit.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      {{- include "helm-toolkit.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "helm-toolkit.selectorLabels" . | nindent 8 }}
      annotations:
        {{- include "helm-toolkit.podAnnotations" . | nindent 8 }}
    spec:
      {{- include "helm-toolkit.podSecurityContext" (dict "context" .) | nindent 6 }}
      serviceAccountName: {{ include "helm-toolkit.serviceAccountName" (dict "context" .) }}
      containers:
      - name: app
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        {{- include "helm-toolkit.securityContext" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.resources" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.livenessProbe" (dict "context" .) | nindent 8 }}
        {{- include "helm-toolkit.readinessProbe" (dict "context" .) | nindent 8 }}
```

### Multi-Component Deployment
```yaml
# API Component
{{- include "helm-toolkit.serviceAccount" (dict "context" . "component" "api") }}
{{- $apiPorts := list (dict "port" 80 "targetPort" 8080 "name" "http") }}
{{- include "helm-toolkit.service" (dict "context" . "component" "api" "ports" $apiPorts) }}
{{- include "helm-toolkit.horizontalPodAutoscaler" (dict "context" . "component" "api") }}

# Worker Component
{{- include "helm-toolkit.serviceAccount" (dict "context" . "component" "worker") }}
{{- include "helm-toolkit.horizontalPodAutoscaler" (dict "context" . "component" "worker") }}

# Database Component
{{- include "helm-toolkit.persistentVolumeClaim" (dict "context" . "component" "data" "size" "20Gi") }}
{{- $dbPorts := list (dict "port" 5432 "name" "postgres") }}
{{- include "helm-toolkit.service" (dict "context" . "component" "database" "type" "ClusterIP" "clusterIP" "None" "ports" $dbPorts) }}
```

## Contributing

When adding new helpers, follow these principles:

1. **DRY (Don't Repeat Yourself)**: Avoid code duplication
2. **Single Responsibility**: Each helper should have one clear purpose
3. **Open/Closed**: Helpers should be open for extension but closed for modification
4. **Dependency Inversion**: Depend on abstractions, not concrete implementations
5. **Component-based**: Support component-specific configuration when applicable

## License

This chart is licensed under the Apache License 2.0.
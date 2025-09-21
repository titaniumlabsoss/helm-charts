{{/*
================================================================================
NETWORKING AND SERVICE DISCOVERY HELPERS
================================================================================
This file contains template helpers for managing Kubernetes networking resources
including Services, Ingress, NetworkPolicies, and monitoring integration.
================================================================================
*/}}

{{/*
helm-toolkit.service

Generates a Kubernetes Service for exposing pods within or outside the cluster.
Supports various service types and advanced networking configurations.

Usage:
  {{- $ports := list (dict "port" 80 "targetPort" 8080 "name" "http") }}
  {{- include "helm-toolkit.service" (dict "context" . "component" "api" "ports" $ports) }}

Parameters:
  context (required): The root template context
  component (optional): Component name for service targeting
  name (optional): Service name override
  type (optional): Service type (default: "ClusterIP")
  ports (required): Array of port definitions
  clusterIP (optional): Specific cluster IP address
  loadBalancerIP (optional): LoadBalancer IP for cloud providers
  sessionAffinity (optional): Session affinity setting (default: "None")

Returns:
  Complete Service YAML manifest

Service Types:
  - ClusterIP: Internal cluster access only (default)
  - NodePort: External access via node ports
  - LoadBalancer: Cloud provider load balancer
  - ExternalName: DNS alias to external service

Port definition structure:
  - port: Service port (external)
  - targetPort: Pod port (internal)
  - protocol: TCP or UDP (default: TCP)
  - name: Port name (required for multiple ports)
  - nodePort: Specific node port (NodePort type only)

Example port configurations:
  # Single HTTP port
  ports:
  - port: 80
    targetPort: 8080
    name: http

  # Multiple ports
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  - port: 443
    targetPort: 8443
    protocol: TCP
    name: https
  - port: 9090
    targetPort: metrics
    name: metrics

Session Affinity:
  - None: No session affinity (default)
  - ClientIP: Route requests from same client IP to same pod

Advanced configurations:
  # Headless service (clusterIP: None)
  {{- include "helm-toolkit.service" (dict
      "context" .
      "component" "database"
      "type" "ClusterIP"
      "clusterIP" "None"
      "ports" $dbPorts
  ) }}

  # LoadBalancer with specific IP
  {{- include "helm-toolkit.service" (dict
      "context" .
      "component" "web"
      "type" "LoadBalancer"
      "loadBalancerIP" "203.0.113.1"
      "ports" $webPorts
  ) }}

Best practices:
  - Use meaningful port names
  - Prefer ClusterIP for internal services
  - Use LoadBalancer sparingly (cost implications)
  - Configure session affinity for stateful apps
  - Use headless services for StatefulSets
*/}}
{{- define "helm-toolkit.service" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $serviceName := .name | default (printf "%s-%s" (include "helm-toolkit.fullname" $context) $component) -}}
{{- $serviceType := .type | default "ClusterIP" -}}
{{- $ports := .ports -}}
{{- $clusterIP := .clusterIP -}}
{{- $loadBalancerIP := .loadBalancerIP -}}
{{- $sessionAffinity := .sessionAffinity | default "None" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceName }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
  {{- $annotations := include "helm-toolkit.annotations" $context }}
  {{- if $annotations }}
  annotations:
    {{- $annotations | nindent 4 }}
  {{- end }}
spec:
  type: {{ $serviceType }}
  {{- if $clusterIP }}
  clusterIP: {{ $clusterIP }}
  {{- end }}
  {{- if and (eq $serviceType "LoadBalancer") $loadBalancerIP }}
  loadBalancerIP: {{ $loadBalancerIP }}
  {{- end }}
  sessionAffinity: {{ $sessionAffinity }}
  ports:
    {{- range $ports }}
    - port: {{ .port }}
      targetPort: {{ .targetPort | default .port }}
      protocol: {{ .protocol | default "TCP" }}
      {{- if .name }}
      name: {{ .name }}
      {{- end }}
      {{- if and (eq $serviceType "NodePort") .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
  selector:
    {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 4 }}
{{- end }}

{{/*
helm-toolkit.ingress

Generates a Kubernetes Ingress for HTTP/HTTPS traffic routing to services.
Supports modern ingress features including path-based and host-based routing.

Usage:
  {{- $hosts := list (dict "host" "api.example.com" "paths" $paths) }}
  {{- include "helm-toolkit.ingress" (dict "context" . "component" "api" "hosts" $hosts) }}

Parameters:
  context (required): The root template context
  component (optional): Component name for ingress targeting
  name (optional): Ingress name override
  className (optional): IngressClass name
  hosts (required): Array of host definitions
  tls (optional): TLS configuration array
  annotations (optional): Ingress-specific annotations

Returns:
  Complete Ingress YAML manifest

Host definition structure:
  - host: Domain name (e.g., "api.example.com")
  - paths: Array of path definitions

Path definition structure:
  - path: URL path (e.g., "/api", "/")
  - pathType: Matching type ("Prefix", "Exact", "ImplementationSpecific")
  - serviceName: Target service name
  - servicePort: Port definition (name or number)

Path Types:
  - Prefix: Matches URL path prefix (most common)
  - Exact: Matches exact URL path
  - ImplementationSpecific: Ingress controller specific

Example configuration:
  {{- $paths := list
      (dict
        "path" "/api"
        "pathType" "Prefix"
        "serviceName" "myapp-api"
        "servicePort" (dict "number" 80)
      )
      (dict
        "path" "/metrics"
        "pathType" "Exact"
        "serviceName" "myapp-metrics"
        "servicePort" (dict "name" "metrics")
      )
  }}
  {{- $hosts := list
      (dict "host" "api.example.com" "paths" $paths)
  }}
  {{- $tls := list
      (dict
        "secretName" "api-tls"
        "hosts" (list "api.example.com")
      )
  }}
  {{- include "helm-toolkit.ingress" (dict
      "context" .
      "component" "api"
      "className" "nginx"
      "hosts" $hosts
      "tls" $tls
      "annotations" (dict
        "nginx.ingress.kubernetes.io/rewrite-target" "/"
        "cert-manager.io/cluster-issuer" "letsencrypt-prod"
      )
  ) }}

Common annotations:
  # Nginx Ingress Controller
  nginx.ingress.kubernetes.io/rewrite-target: "/"
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/rate-limit: "100"

  # Cert-Manager
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
  cert-manager.io/acme-challenge-type: "http01"

  # AWS Load Balancer Controller
  alb.ingress.kubernetes.io/scheme: "internet-facing"
  alb.ingress.kubernetes.io/target-type: "ip"

TLS Configuration:
  - Automatic certificate management with cert-manager
  - Manual certificate specification
  - SNI (Server Name Indication) support

Best practices:
  - Use specific IngressClass names
  - Configure TLS for production
  - Use path prefixes for API routing
  - Set appropriate timeouts and limits
  - Monitor ingress performance
  - Use rate limiting for public APIs
*/}}
{{- define "helm-toolkit.ingress" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $ingressName := .name | default (printf "%s-%s" (include "helm-toolkit.fullname" $context) $component) -}}
{{- $className := .className -}}
{{- $hosts := .hosts -}}
{{- $tls := .tls -}}
{{- $annotations := .annotations -}}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $ingressName }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
  {{- if or $annotations (include "helm-toolkit.annotations" $context) }}
  annotations:
    {{- include "helm-toolkit.annotations" $context | nindent 4 }}
    {{- with $annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
spec:
  {{- if $className }}
  ingressClassName: {{ $className }}
  {{- end }}
  {{- if $tls }}
  tls:
    {{- toYaml $tls | nindent 4 }}
  {{- end }}
  rules:
    {{- range $hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ .serviceName }}
                port:
                  {{- if .servicePort.name }}
                  name: {{ .servicePort.name }}
                  {{- else }}
                  number: {{ .servicePort.number }}
                  {{- end }}
          {{- end }}
    {{- end }}
{{- end }}

{{/*
helm-toolkit.networkPolicy

Generates a NetworkPolicy for controlling network traffic to and from pods.
Implements micro-segmentation and zero-trust networking principles.

Usage:
  {{- include "helm-toolkit.networkPolicy" (dict "context" . "component" "api" "ingress" $ingressRules) }}

Parameters:
  context (required): The root template context
  component (optional): Component name for pod selection
  name (optional): NetworkPolicy name override
  ingress (optional): Array of ingress rules
  egress (optional): Array of egress rules
  policyTypes (optional): Policy types array (default: ["Ingress"])

Returns:
  Complete NetworkPolicy YAML manifest

Policy Types:
  - Ingress: Controls incoming traffic to pods
  - Egress: Controls outgoing traffic from pods
  - Both can be specified together

Rule structure:
  Each rule can specify:
  - from/to: Source/destination selectors
  - ports: Allowed ports and protocols

Selector types:
  - podSelector: Select pods by labels
  - namespaceSelector: Select entire namespaces
  - ipBlock: Select IP address ranges

Example ingress rules:
  {{- $ingressRules := list
      # Allow traffic from frontend pods
      (dict
        "from" (list
          (dict "podSelector" (dict "matchLabels" (dict "app.kubernetes.io/component" "frontend")))
        )
        "ports" (list
          (dict "protocol" "TCP" "port" 8080)
        )
      )
      # Allow traffic from specific namespace
      (dict
        "from" (list
          (dict "namespaceSelector" (dict "matchLabels" (dict "name" "monitoring")))
        )
        "ports" (list
          (dict "protocol" "TCP" "port" 9090)
        )
      )
      # Allow traffic from specific IP range
      (dict
        "from" (list
          (dict "ipBlock" (dict "cidr" "10.0.0.0/8" "except" (list "10.0.1.0/24")))
        )
      )
  }}

Example egress rules:
  {{- $egressRules := list
      # Allow DNS resolution
      (dict
        "to" (list)
        "ports" (list
          (dict "protocol" "UDP" "port" 53)
          (dict "protocol" "TCP" "port" 53)
        )
      )
      # Allow HTTPS to external services
      (dict
        "to" (list)
        "ports" (list
          (dict "protocol" "TCP" "port" 443)
        )
      )
      # Allow database access
      (dict
        "to" (list
          (dict "podSelector" (dict "matchLabels" (dict "app.kubernetes.io/component" "database")))
        )
        "ports" (list
          (dict "protocol" "TCP" "port" 5432)
        )
      )
  }}

Default behavior:
  - Without NetworkPolicy: All traffic allowed
  - With NetworkPolicy: Only explicitly allowed traffic
  - Empty rules array: Deny all traffic of that type

Common patterns:
  # Deny all ingress traffic
  {{- include "helm-toolkit.networkPolicy" (dict
      "context" .
      "component" "secure-app"
      "policyTypes" (list "Ingress")
  ) }}

  # Allow only internal cluster traffic
  {{- include "helm-toolkit.networkPolicy" (dict
      "context" .
      "component" "internal-api"
      "policyTypes" (list "Ingress" "Egress")
      "ingress" $internalIngressRules
      "egress" $internalEgressRules
  ) }}

Security considerations:
  - NetworkPolicies are cumulative (multiple policies can apply)
  - Requires CNI plugin support (Calico, Cilium, etc.)
  - Default deny-all is most secure
  - Monitor network policy effectiveness

Best practices:
  - Implement least privilege access
  - Use namespace isolation
  - Allow necessary system traffic (DNS, metrics)
  - Test policies in staging environments
  - Document network requirements
  - Regular policy auditing
*/}}
{{- define "helm-toolkit.networkPolicy" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $policyName := .name | default (printf "%s-%s" (include "helm-toolkit.fullname" $context) $component) -}}
{{- $ingress := .ingress -}}
{{- $egress := .egress -}}
{{- $policyTypes := .policyTypes | default (list "Ingress") -}}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $policyName }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 6 }}
  policyTypes:
    {{- toYaml $policyTypes | nindent 4 }}
  {{- if $ingress }}
  ingress:
    {{- toYaml $ingress | nindent 4 }}
  {{- end }}
  {{- if $egress }}
  egress:
    {{- toYaml $egress | nindent 4 }}
  {{- end }}
{{- end }}

{{/*
helm-toolkit.serviceMonitor

Generates a ServiceMonitor for Prometheus Operator integration.
Enables automatic service discovery and metrics collection.

Usage:
  {{- $endpoints := list (dict "port" "metrics" "path" "/metrics") }}
  {{- include "helm-toolkit.serviceMonitor" (dict "context" . "component" "api" "endpoints" $endpoints) }}

Parameters:
  context (required): The root template context
  component (optional): Component name for service selection
  name (optional): ServiceMonitor name override
  endpoints (required): Array of endpoint configurations
  jobLabel (optional): Service label to use as job name
  targetLabels (optional): Labels to copy from service to metrics

Returns:
  Complete ServiceMonitor YAML manifest

Endpoint configuration:
  - port: Service port name or number
  - path: Metrics endpoint path (default: "/metrics")
  - interval: Scrape interval (default: 30s)
  - timeout: Scrape timeout (default: 10s)
  - scheme: HTTP or HTTPS (default: HTTP)
  - tlsConfig: TLS configuration for HTTPS
  - basicAuth: Basic authentication configuration
  - bearerTokenFile: Bearer token file path
  - honorLabels: Preserve metric labels from target
  - metricRelabelings: Relabeling rules for metrics
  - relabelings: Relabeling rules for targets

Example endpoints:
  {{- $endpoints := list
      # Basic metrics endpoint
      (dict
        "port" "metrics"
        "path" "/metrics"
        "interval" "30s"
        "timeout" "10s"
      )
      # HTTPS endpoint with custom config
      (dict
        "port" "https-metrics"
        "path" "/secure-metrics"
        "scheme" "https"
        "tlsConfig" (dict
          "insecureSkipVerify" true
        )
        "interval" "60s"
      )
      # Endpoint with authentication
      (dict
        "port" "metrics"
        "bearerTokenFile" "/var/run/secrets/kubernetes.io/serviceaccount/token"
        "honorLabels" true
      )
  }}

Label management:
  # Job label: Use service label as Prometheus job name
  jobLabel: "app.kubernetes.io/name"

  # Target labels: Copy service labels to metrics
  targetLabels:
  - "app.kubernetes.io/version"
  - "app.kubernetes.io/component"

Metric relabeling examples:
  metricRelabelings:
  # Drop high-cardinality metrics
  - sourceLabels: [__name__]
    regex: "expensive_metric_.*"
    action: drop
  # Rename metric labels
  - sourceLabels: [instance]
    targetLabel: pod
    action: replace

Target relabeling examples:
  relabelings:
  # Add custom labels
  - targetLabel: cluster
    replacement: "production"
    action: replace
  # Modify target address
  - sourceLabels: [__address__]
    targetLabel: __address__
    regex: "(.+):(.+)"
    replacement: "${1}:9090"
    action: replace

Prometheus Operator requirements:
  - ServiceMonitor must be in same namespace as Prometheus
  - Or use serviceMonitorNamespaceSelector in Prometheus config
  - Service must have matching labels for selection
  - Endpoints must be accessible from Prometheus pods

Best practices:
  - Use descriptive job labels
  - Set appropriate scrape intervals
  - Configure timeouts based on endpoint response time
  - Use TLS for production environments
  - Implement metric relabeling for cost optimization
  - Monitor ServiceMonitor status in Prometheus UI
*/}}
{{- define "helm-toolkit.serviceMonitor" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $monitorName := .name | default (printf "%s-%s" (include "helm-toolkit.fullname" $context) $component) -}}
{{- $endpoints := .endpoints -}}
{{- $jobLabel := .jobLabel -}}
{{- $targetLabels := .targetLabels -}}
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ $monitorName }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 6 }}
  {{- if $jobLabel }}
  jobLabel: {{ $jobLabel }}
  {{- end }}
  {{- if $targetLabels }}
  targetLabels:
    {{- toYaml $targetLabels | nindent 4 }}
  {{- end }}
  endpoints:
    {{- toYaml $endpoints | nindent 4 }}
{{- end }}
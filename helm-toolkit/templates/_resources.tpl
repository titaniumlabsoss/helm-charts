{{/*
================================================================================
RESOURCE MANAGEMENT AND SCHEDULING HELPERS
================================================================================
This file contains template helpers for managing Kubernetes resource allocation,
node scheduling, and workload distribution across the cluster.
================================================================================
*/}}

{{/*
helm-toolkit.resources

Defines resource limits and requests for containers.
Supports component-specific resource configurations for multi-component applications.

Usage:
  {{ include "helm-toolkit.resources" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific resources (default: "default")

Returns:
  Kubernetes resources specification in YAML format

Configuration:
  .Values.resources: Default resource configuration
  .Values.resources.<component>: Component-specific resource configuration

Supported resource types:
  - CPU (limits and requests)
  - Memory (limits and requests)
  - Ephemeral storage (limits and requests)

Example values.yaml:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
      ephemeral-storage: 1Gi
    requests:
      cpu: 100m
      memory: 128Mi
      ephemeral-storage: 100Mi

  # Component-specific resources
  resources:
    api:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 256Mi
    worker:
      limits:
        cpu: 2000m
        memory: 2Gi
      requests:
        cpu: 500m
        memory: 512Mi

Best practices:
  - Always set resource requests for proper scheduling
  - Set resource limits to prevent resource starvation
  - Use different profiles for different workload types
*/}}
{{- define "helm-toolkit.resources" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $resources := index $context.Values "resources" $component | default $context.Values.resources -}}
{{- if $resources }}
resources:
  {{- if $resources.limits }}
  limits:
    {{- if $resources.limits.cpu }}
    cpu: {{ $resources.limits.cpu }}
    {{- end }}
    {{- if $resources.limits.memory }}
    memory: {{ $resources.limits.memory }}
    {{- end }}
    {{- if $resources.limits.ephemeral-storage }}
    ephemeral-storage: {{ $resources.limits.ephemeral-storage }}
    {{- end }}
  {{- end }}
  {{- if $resources.requests }}
  requests:
    {{- if $resources.requests.cpu }}
    cpu: {{ $resources.requests.cpu }}
    {{- end }}
    {{- if $resources.requests.memory }}
    memory: {{ $resources.requests.memory }}
    {{- end }}
    {{- if $resources.requests.ephemeral-storage }}
    ephemeral-storage: {{ $resources.requests.ephemeral-storage }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.nodeSelector

Configures node selection for pod scheduling based on node labels.
Allows targeting specific nodes or node groups for workload placement.

Usage:
  {{ include "helm-toolkit.nodeSelector" (dict "context" . "component" "database") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific node selection

Returns:
  Node selector configuration in YAML format

Configuration:
  .Values.nodeSelector: Default node selector
  .Values.nodeSelector.<component>: Component-specific node selector

Example values.yaml:
  nodeSelector:
    kubernetes.io/arch: amd64
    node-type: compute

  # Component-specific node selection
  nodeSelector:
    database:
      kubernetes.io/arch: amd64
      node-type: storage
      disk-type: ssd
    frontend:
      kubernetes.io/arch: amd64
      node-type: edge

Use cases:
  - Hardware-specific workloads (GPU, high-memory)
  - Compliance requirements (data locality)
  - Performance optimization (SSD storage, high CPU)
  - Cost optimization (spot instances, smaller instances)

Output example:
  nodeSelector:
    kubernetes.io/arch: amd64
    node-type: compute
*/}}
{{- define "helm-toolkit.nodeSelector" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $nodeSelector := index $context.Values "nodeSelector" $component | default $context.Values.nodeSelector -}}
{{- if $nodeSelector }}
nodeSelector:
  {{- toYaml $nodeSelector | nindent 2 }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.tolerations

Configures pod tolerations to allow scheduling on nodes with specific taints.
Essential for scheduling workloads on specialized or tainted nodes.

Usage:
  {{ include "helm-toolkit.tolerations" (dict "context" . "component" "system") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific tolerations

Returns:
  Tolerations configuration in YAML format

Configuration:
  .Values.tolerations: Default tolerations
  .Values.tolerations.<component>: Component-specific tolerations

Example values.yaml:
  tolerations:
  - key: "node.kubernetes.io/not-ready"
    operator: "Exists"
    effect: "NoExecute"
    tolerationSeconds: 300
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"

Toleration operators:
  - Equal: Key/value must match exactly
  - Exists: Only key must exist (ignore value)

Taint effects:
  - NoSchedule: Prevents new pods from being scheduled
  - PreferNoSchedule: Soft version of NoSchedule
  - NoExecute: Evicts existing pods that don't tolerate

Use cases:
  - Dedicated nodes for specific workloads
  - Node maintenance and upgrades
  - Spot instance handling
  - Hardware-specific scheduling
*/}}
{{- define "helm-toolkit.tolerations" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $tolerations := index $context.Values "tolerations" $component | default $context.Values.tolerations -}}
{{- if $tolerations }}
tolerations:
  {{- toYaml $tolerations | nindent 2 }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.affinity

Configures pod affinity and anti-affinity rules for workload placement.
Includes built-in pod anti-affinity support for high availability.

Usage:
  {{ include "helm-toolkit.affinity" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific affinity

Returns:
  Affinity configuration in YAML format

Configuration:
  .Values.affinity: Custom affinity rules
  .Values.affinity.<component>: Component-specific affinity rules
  .Values.podAntiAffinity: Built-in pod anti-affinity configuration

Built-in Pod Anti-Affinity:
  .Values.podAntiAffinity.enabled: Enable automatic pod anti-affinity
  .Values.podAntiAffinity.type: "hard" or "soft" anti-affinity
  .Values.podAntiAffinity.weight: Weight for soft anti-affinity (default: 100)
  .Values.podAntiAffinity.topologyKey: Topology key (default: "kubernetes.io/hostname")

Example values.yaml:
  # Built-in pod anti-affinity
  podAntiAffinity:
    enabled: true
    type: soft
    weight: 100
    topologyKey: kubernetes.io/hostname

  # Custom affinity rules
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64

Affinity types:
  - nodeAffinity: Attract/repel pods to/from nodes
  - podAffinity: Attract pods to run near other pods
  - podAntiAffinity: Repel pods from running near other pods

Use cases:
  - High availability (spread pods across nodes/zones)
  - Performance (co-locate related services)
  - Compliance (separate sensitive workloads)
  - Resource optimization (balance cluster load)
*/}}
{{- define "helm-toolkit.affinity" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $affinity := index $context.Values "affinity" $component | default $context.Values.affinity -}}
{{- if $affinity }}
affinity:
  {{- toYaml $affinity | nindent 2 }}
{{- else if $context.Values.podAntiAffinity.enabled }}
affinity:
  podAntiAffinity:
    {{- if eq $context.Values.podAntiAffinity.type "hard" }}
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          {{- include "helm-toolkit.selectorLabels" $context | nindent 10 }}
      topologyKey: {{ $context.Values.podAntiAffinity.topologyKey | default "kubernetes.io/hostname" }}
    {{- else if eq $context.Values.podAntiAffinity.type "soft" }}
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: {{ $context.Values.podAntiAffinity.weight | default 100 }}
      podAffinityTerm:
        labelSelector:
          matchLabels:
            {{- include "helm-toolkit.selectorLabels" $context | nindent 12 }}
        topologyKey: {{ $context.Values.podAntiAffinity.topologyKey | default "kubernetes.io/hostname" }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.priorityClassName

Sets the priority class for pods to influence scheduling decisions.
Higher priority pods are scheduled before lower priority pods.

Usage:
  {{ include "helm-toolkit.priorityClassName" (dict "context" . "component" "critical") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific priority

Returns:
  Priority class name specification

Configuration:
  .Values.priorityClassName: Default priority class
  .Values.priorityClassName.<component>: Component-specific priority class

Example values.yaml:
  priorityClassName: high-priority

  # Component-specific priorities
  priorityClassName:
    api: system-cluster-critical
    worker: low-priority
    database: high-priority

Common priority classes:
  - system-cluster-critical: Highest priority for cluster components
  - system-node-critical: High priority for node-level components
  - high-priority: Custom high priority class
  - default: Default priority (no class specified)
  - low-priority: Custom low priority class

Use cases:
  - Critical system components
  - Revenue-generating services
  - Batch jobs (low priority)
  - Emergency workloads
  - Resource contention management

Note: Priority classes must be created separately in the cluster
*/}}
{{- define "helm-toolkit.priorityClassName" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $priorityClassName := index $context.Values "priorityClassName" $component | default $context.Values.priorityClassName -}}
{{- if $priorityClassName }}
priorityClassName: {{ $priorityClassName }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.topologySpreadConstraints

Configures topology spread constraints to control pod distribution across cluster topology.
Ensures even distribution of pods across zones, nodes, or other topology domains.

Usage:
  {{ include "helm-toolkit.topologySpreadConstraints" (dict "context" . "component" "frontend") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific constraints

Returns:
  Topology spread constraints configuration in YAML format

Configuration:
  .Values.topologySpreadConstraints: Default topology spread constraints
  .Values.topologySpreadConstraints.<component>: Component-specific constraints

Example values.yaml:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: myapp
  - maxSkew: 2
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway

Constraint parameters:
  - maxSkew: Maximum difference in pod count between topology domains
  - topologyKey: Node label key that defines topology domain
  - whenUnsatisfiable: Action when constraint cannot be satisfied
    * DoNotSchedule: Hard constraint (prevent scheduling)
    * ScheduleAnyway: Soft constraint (prefer but allow)
  - labelSelector: Selector for pods to consider in the calculation

Common topology keys:
  - topology.kubernetes.io/zone: Availability zones
  - topology.kubernetes.io/region: Cloud regions
  - kubernetes.io/hostname: Individual nodes
  - node.kubernetes.io/instance-type: Instance types

Use cases:
  - High availability across zones
  - Even distribution across nodes
  - Cost optimization (spread across instance types)
  - Performance optimization (avoid hotspots)
  - Compliance requirements (data distribution)
*/}}
{{- define "helm-toolkit.topologySpreadConstraints" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $topologySpreadConstraints := index $context.Values "topologySpreadConstraints" $component | default $context.Values.topologySpreadConstraints -}}
{{- if $topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml $topologySpreadConstraints | nindent 2 }}
{{- end }}
{{- end }}
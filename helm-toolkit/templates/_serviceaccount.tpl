{{/*
================================================================================
SERVICE ACCOUNT AND RBAC HELPERS
================================================================================
This file contains template helpers for managing Kubernetes service accounts,
RBAC (Role-Based Access Control) roles, and security permissions.
================================================================================
*/}}

{{/*
helm-toolkit.serviceAccountName

Determines the service account name to use for pods.
Supports both creating new service accounts and using existing ones.

Usage:
  serviceAccountName: {{ include "helm-toolkit.serviceAccountName" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific service accounts

Returns:
  Service account name string

Configuration:
  .Values.serviceAccount: Default service account configuration
  .Values.serviceAccount.<component>: Component-specific service account
  .Values.serviceAccount.create: Whether to create a new service account
  .Values.serviceAccount.name: Name override for the service account

Logic:
  1. If create=true: Use provided name or generate from fullname
  2. If create=false: Use provided name or "default" system account

Example values.yaml:
  serviceAccount:
    create: true
    name: "custom-service-account"
    annotations: {}
    automount: false

  # Component-specific service accounts
  serviceAccount:
    api:
      create: true
      name: "api-service-account"
    worker:
      create: false
      name: "existing-worker-account"

Best practices:
  - Use dedicated service accounts for different components
  - Disable automount unless required
  - Apply principle of least privilege
*/}}
{{- define "helm-toolkit.serviceAccountName" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $serviceAccount := index $context.Values "serviceAccount" $component | default $context.Values.serviceAccount -}}
{{- if $serviceAccount.create }}
{{- default (include "helm-toolkit.fullname" $context) $serviceAccount.name }}
{{- else }}
{{- default "default" $serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.serviceAccountAnnotations

Generates annotations for service accounts.
Commonly used for cloud provider integrations and IAM role bindings.

Usage:
  annotations:
    {{- include "helm-toolkit.serviceAccountAnnotations" (dict "context" . "component" "api") | nindent 4 }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific annotations

Returns:
  Service account annotations in YAML format

Configuration:
  .Values.serviceAccount.annotations: Annotations to apply
  .Values.serviceAccount.<component>.annotations: Component-specific annotations

Common annotations:
  # AWS IAM Role for Service Accounts (IRSA)
  eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/MyRole"

  # Google Workload Identity
  iam.gke.io/gcp-service-account: "my-service-account@project.iam.gserviceaccount.com"

  # Azure Workload Identity
  azure.workload.identity/client-id: "12345678-1234-1234-1234-123456789012"

  # Custom annotations
  example.com/team: "platform"
  example.com/environment: "production"

Example values.yaml:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/S3AccessRole"
      example.com/purpose: "data-processing"
*/}}
{{- define "helm-toolkit.serviceAccountAnnotations" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $serviceAccount := index $context.Values "serviceAccount" $component | default $context.Values.serviceAccount -}}
{{- with $serviceAccount.annotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.serviceAccount

Generates a complete ServiceAccount manifest.
Includes proper labels, annotations, and security configurations.

Usage:
  {{- include "helm-toolkit.serviceAccount" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific service accounts

Returns:
  Complete ServiceAccount YAML manifest

Configuration:
  .Values.serviceAccount.create: Whether to create the service account
  .Values.serviceAccount.name: Service account name override
  .Values.serviceAccount.annotations: Annotations to apply
  .Values.serviceAccount.automount: Whether to automount the service account token

Features:
  - Automatic name generation based on chart fullname
  - Component-specific labeling
  - Cloud provider integration support via annotations
  - Security-focused defaults (automount disabled by default)

Security considerations:
  - automount defaults to false for security
  - Enable automount only when pods need to access Kubernetes API
  - Use annotations for cloud provider IAM integration
  - Apply principle of least privilege with RBAC

Example output:
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: myapp-api
    labels:
      app.kubernetes.io/name: myapp
      app.kubernetes.io/component: api
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123:role/MyRole"
  automountServiceAccountToken: false
*/}}
{{- define "helm-toolkit.serviceAccount" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $serviceAccount := index $context.Values "serviceAccount" $component | default $context.Values.serviceAccount -}}
{{- if $serviceAccount.create -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "helm-toolkit.serviceAccountName" (dict "context" $context "component" $component) }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
  {{- $annotations := include "helm-toolkit.serviceAccountAnnotations" (dict "context" $context "component" $component) }}
  {{- if $annotations }}
  annotations:
    {{- $annotations | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ $serviceAccount.automount | default false }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.role

Generates a Kubernetes Role for namespace-scoped RBAC permissions.
Roles define what actions can be performed on resources within a namespace.

Usage:
  {{- include "helm-toolkit.role" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific roles

Returns:
  Complete Role YAML manifest

Configuration:
  .Values.rbac.create: Whether to create RBAC resources
  .Values.rbac.rules: Array of policy rules for the role
  .Values.rbac.<component>.rules: Component-specific rules

Policy rule structure:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update"]

Common verbs:
  - get: Retrieve a specific resource
  - list: List resources of a type
  - watch: Watch for changes to resources
  - create: Create new resources
  - update: Modify existing resources
  - patch: Apply partial updates
  - delete: Remove resources
  - deletecollection: Remove multiple resources

Example values.yaml:
  rbac:
    create: true
    rules:
    - apiGroups: [""]
      resources: ["configmaps", "secrets"]
      verbs: ["get", "list"]
    - apiGroups: ["apps"]
      resources: ["deployments"]
      verbs: ["get", "list", "watch"]

Use cases:
  - Reading configuration from ConfigMaps/Secrets
  - Monitoring other workloads in the same namespace
  - Managing related resources (leader election)
  - Service discovery within namespace
*/}}
{{- define "helm-toolkit.role" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $rbac := index $context.Values "rbac" $component | default $context.Values.rbac -}}
{{- if and $rbac.create $rbac.rules }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
rules:
{{- toYaml $rbac.rules | nindent 0 }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.clusterRole

Generates a Kubernetes ClusterRole for cluster-wide RBAC permissions.
ClusterRoles define what actions can be performed on resources across all namespaces.

Usage:
  {{- include "helm-toolkit.clusterRole" (dict "context" . "component" "controller") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific cluster roles

Returns:
  Complete ClusterRole YAML manifest

Configuration:
  .Values.rbac.create: Whether to create RBAC resources
  .Values.rbac.clusterRules: Array of cluster-wide policy rules
  .Values.rbac.<component>.clusterRules: Component-specific cluster rules

Cluster-scoped resources:
  - nodes
  - persistentvolumes
  - clusterroles
  - clusterrolebindings
  - customresourcedefinitions
  - namespaces
  - storageclasses

Example values.yaml:
  rbac:
    create: true
    clusterRules:
    - apiGroups: [""]
      resources: ["nodes"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["persistentvolumes"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["storage.k8s.io"]
      resources: ["storageclasses"]
      verbs: ["get", "list"]

Security warning:
  ClusterRoles grant permissions across ALL namespaces.
  Use with extreme caution and apply principle of least privilege.

Common use cases:
  - Cluster monitoring and metrics collection
  - Node management and resource monitoring
  - Custom resource controllers
  - Cluster-wide operators
  - Cross-namespace service discovery

Best practices:
  - Minimize cluster-wide permissions
  - Use namespace-scoped Roles when possible
  - Regularly audit cluster permissions
  - Document why cluster access is needed
*/}}
{{- define "helm-toolkit.clusterRole" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $rbac := index $context.Values "rbac" $component | default $context.Values.rbac -}}
{{- if and $rbac.create $rbac.clusterRules }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
rules:
{{- toYaml $rbac.clusterRules | nindent 0 }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.roleBinding

Generates a RoleBinding to bind a Role to a ServiceAccount within a namespace.
Establishes the connection between permissions (Role) and identity (ServiceAccount).

Usage:
  {{- include "helm-toolkit.roleBinding" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific bindings

Returns:
  Complete RoleBinding YAML manifest

Configuration:
  .Values.rbac.create: Whether to create RBAC resources
  .Values.rbac.rules: Must be present to create the binding

Generated automatically when:
  - rbac.create is true
  - rbac.rules is defined (creates corresponding Role)

Binding structure:
  - Links the generated Role to the ServiceAccount
  - Scoped to the current namespace
  - Uses the same component naming convention

Example output:
  apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: myapp-api
    namespace: default
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: myapp-api
  subjects:
  - kind: ServiceAccount
    name: myapp-api
    namespace: default

Security model:
  - ServiceAccount: Identity (who)
  - Role: Permissions (what)
  - RoleBinding: Association (who can do what)

Best practices:
  - One RoleBinding per component for clarity
  - Use descriptive names for troubleshooting
  - Regular auditing of permissions
  - Principle of least privilege
*/}}
{{- define "helm-toolkit.roleBinding" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $rbac := index $context.Values "rbac" $component | default $context.Values.rbac -}}
{{- if and $rbac.create $rbac.rules }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
subjects:
- kind: ServiceAccount
  name: {{ include "helm-toolkit.serviceAccountName" (dict "context" $context "component" $component) }}
  namespace: {{ $context.Release.Namespace }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.clusterRoleBinding

Generates a ClusterRoleBinding to bind a ClusterRole to a ServiceAccount cluster-wide.
Grants cluster-wide permissions to the specified ServiceAccount.

Usage:
  {{- include "helm-toolkit.clusterRoleBinding" (dict "context" . "component" "controller") }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific bindings

Returns:
  Complete ClusterRoleBinding YAML manifest

Configuration:
  .Values.rbac.create: Whether to create RBAC resources
  .Values.rbac.clusterRules: Must be present to create the binding

Generated automatically when:
  - rbac.create is true
  - rbac.clusterRules is defined (creates corresponding ClusterRole)

Binding characteristics:
  - Links the generated ClusterRole to the ServiceAccount
  - Grants cluster-wide permissions
  - ServiceAccount remains namespace-scoped
  - Permissions apply across all namespaces

Example output:
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: myapp-controller
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: myapp-controller
  subjects:
  - kind: ServiceAccount
    name: myapp-controller
    namespace: default

Security implications:
  - Grants permissions across ALL namespaces
  - Potentially high-privilege access
  - Requires careful security review
  - Should be minimally scoped

Common use cases:
  - Kubernetes operators and controllers
  - Cluster monitoring systems
  - Cross-namespace service mesh components
  - Infrastructure management tools

Best practices:
  - Document cluster-wide access requirements
  - Regular security audits
  - Use least privilege principle
  - Consider namespace-scoped alternatives first
  - Monitor for privilege escalation
*/}}
{{- define "helm-toolkit.clusterRoleBinding" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $rbac := index $context.Values "rbac" $component | default $context.Values.rbac -}}
{{- if and $rbac.create $rbac.clusterRules }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
subjects:
- kind: ServiceAccount
  name: {{ include "helm-toolkit.serviceAccountName" (dict "context" $context "component" $component) }}
  namespace: {{ $context.Release.Namespace }}
{{- end }}
{{- end }}
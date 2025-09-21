{{/*
================================================================================
LABELS AND NAMING HELPERS
================================================================================
This file contains template helpers for generating consistent Kubernetes labels,
annotations, and naming conventions following best practices.
================================================================================
*/}}

{{/*
helm-toolkit.labels

Generates the complete set of standard Kubernetes labels for resources.
Includes chart information, version, and management metadata.

Usage:
  {{ include "helm-toolkit.labels" . }}

Parameters:
  . (required): The root context containing Chart and Release information

Returns:
  Standard Kubernetes labels in YAML format:
  - helm.sh/chart: Chart name and version
  - app.kubernetes.io/name: Application name
  - app.kubernetes.io/instance: Release instance name
  - app.kubernetes.io/version: Application version (if available)
  - app.kubernetes.io/managed-by: Helm management indicator

Example output:
  helm.sh/chart: myapp-1.0.0
  app.kubernetes.io/name: myapp
  app.kubernetes.io/instance: myapp-production
  app.kubernetes.io/version: "1.2.3"
  app.kubernetes.io/managed-by: Helm
*/}}
{{- define "helm-toolkit.labels" -}}
helm.sh/chart: {{ include "helm-toolkit.chart" . }}
{{ include "helm-toolkit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
helm-toolkit.selectorLabels

Generates selector labels used for matching pods with services and deployments.
These labels should remain consistent and are used for pod selection.

Usage:
  {{ include "helm-toolkit.selectorLabels" . }}

Parameters:
  . (required): The root context containing Chart and Release information

Returns:
  Selector labels in YAML format:
  - app.kubernetes.io/name: Application name
  - app.kubernetes.io/instance: Release instance name

Example output:
  app.kubernetes.io/name: myapp
  app.kubernetes.io/instance: myapp-production

Note: These labels should not change between upgrades as they are used
      for resource selection and matching.
*/}}
{{- define "helm-toolkit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-toolkit.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
helm-toolkit.chart

Creates a chart label value combining chart name and version.
Formats the value to be Kubernetes-compliant by replacing invalid characters.

Usage:
  {{ include "helm-toolkit.chart" . }}

Parameters:
  . (required): The root context containing Chart information

Returns:
  Formatted chart name and version string

Example:
  Input: Chart.Name="my-app", Chart.Version="1.0.0+build123"
  Output: "my-app-1.0.0_build123"

Notes:
  - Replaces "+" with "_" for Kubernetes compatibility
  - Truncates to 63 characters (DNS naming limit)
  - Removes trailing "-" characters
*/}}
{{- define "helm-toolkit.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
helm-toolkit.name

Expands the name of the chart, allowing for override via values.
Uses nameOverride from values if provided, otherwise uses chart name.

Usage:
  {{ include "helm-toolkit.name" . }}

Parameters:
  . (required): The root context containing Chart and Values

Returns:
  The application name string

Configuration:
  .Values.nameOverride: Optional override for the chart name

Example:
  Chart.Name="my-application"
  Values.nameOverride="custom-name"
  Result: "custom-name"

  Chart.Name="my-application"
  Values.nameOverride=""
  Result: "my-application"

Notes:
  - Truncated to 63 characters for DNS compatibility
  - Trailing dashes removed
*/}}
{{- define "helm-toolkit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
helm-toolkit.fullname

Creates a fully qualified application name for Kubernetes resources.
Handles various naming scenarios and provides override capabilities.

Usage:
  {{ include "helm-toolkit.fullname" . }}

Parameters:
  . (required): The root context containing Chart, Release, and Values

Returns:
  The fully qualified resource name string

Configuration:
  .Values.fullnameOverride: Complete override for the full name
  .Values.nameOverride: Override for just the app name portion

Logic:
  1. If fullnameOverride is set, use it directly
  2. If release name contains chart name, use release name only
  3. Otherwise, combine release name and chart name

Examples:
  Release.Name="prod-myapp", Chart.Name="myapp"
  Result: "prod-myapp" (release contains chart name)

  Release.Name="production", Chart.Name="myapp"
  Result: "production-myapp" (standard combination)

  Values.fullnameOverride="custom-full-name"
  Result: "custom-full-name" (complete override)

Notes:
  - Truncated to 63 characters (Kubernetes DNS limit)
  - Trailing dashes removed
  - Ensures unique naming across different releases
*/}}
{{- define "helm-toolkit.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.componentLabels

Generates labels for a specific component within a multi-component application.
Extends the standard labels with component-specific information.

Usage:
  {{ include "helm-toolkit.componentLabels" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (required): The component name (e.g., "api", "worker", "frontend")

Returns:
  Complete label set including component information

Example:
  {{ include "helm-toolkit.componentLabels" (dict "context" . "component" "api") }}

Output:
  helm.sh/chart: myapp-1.0.0
  app.kubernetes.io/name: myapp
  app.kubernetes.io/instance: myapp-production
  app.kubernetes.io/version: "1.2.3"
  app.kubernetes.io/managed-by: Helm
  app.kubernetes.io/component: api

Use cases:
  - Multi-tier applications (frontend, backend, database)
  - Microservices architectures
  - Applications with different operational roles
*/}}
{{- define "helm-toolkit.componentLabels" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{ include "helm-toolkit.labels" $context }}
app.kubernetes.io/component: {{ $component }}
{{- end }}

{{/*
helm-toolkit.componentSelectorLabels

Generates selector labels for a specific component.
Used for service and deployment selectors in multi-component applications.

Usage:
  {{ include "helm-toolkit.componentSelectorLabels" (dict "context" . "component" "api") }}

Parameters:
  context (required): The root template context
  component (required): The component name

Returns:
  Selector labels with component information

Example:
  selector:
    matchLabels:
      {{- include "helm-toolkit.componentSelectorLabels" (dict "context" . "component" "api") | nindent 6 }}

Output:
  app.kubernetes.io/name: myapp
  app.kubernetes.io/instance: myapp-production
  app.kubernetes.io/component: api

Notes:
  - These labels should remain stable across updates
  - Used for pod selection by services and deployments
  - Component-specific for proper traffic routing
*/}}
{{- define "helm-toolkit.componentSelectorLabels" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{ include "helm-toolkit.selectorLabels" $context }}
app.kubernetes.io/component: {{ $component }}
{{- end }}

{{/*
helm-toolkit.annotations

Generates common annotations for Kubernetes resources.
Allows for consistent annotation application across all resources.

Usage:
  {{ include "helm-toolkit.annotations" . }}

Parameters:
  . (required): The root context containing Values

Returns:
  Common annotations in YAML format

Configuration:
  .Values.commonAnnotations: Dictionary of annotations to apply

Example values.yaml:
  commonAnnotations:
    "example.com/team": "platform"
    "example.com/environment": "production"
    "example.com/cost-center": "engineering"

Output:
  example.com/team: "platform"
  example.com/environment: "production"
  example.com/cost-center: "engineering"

Use cases:
  - Team ownership information
  - Environment labeling
  - Cost tracking
  - Monitoring configuration
  - Policy enforcement
*/}}
{{- define "helm-toolkit.annotations" -}}
{{- with .Values.commonAnnotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.podAnnotations

Generates pod-specific annotations including configuration checksums.
Automatically includes checksums for ConfigMaps and Secrets to trigger
pod restarts when configuration changes.

Usage:
  {{ include "helm-toolkit.podAnnotations" . }}

Parameters:
  . (required): The root context containing Values and Template

Returns:
  Pod annotations including configuration checksums

Configuration:
  .Values.podAnnotations: Custom pod annotations
  .Values.configMap: Triggers configmap checksum if present
  .Values.secret: Triggers secret checksum if present

Features:
  - Custom annotations from values
  - Automatic config change detection via checksums
  - Triggers rolling updates when configuration changes

Example output:
  custom.annotation/example: "value"
  checksum/config: "sha256:abc123..."
  checksum/secret: "sha256:def456..."

Benefits:
  - Ensures pods restart when configuration changes
  - Provides visibility into configuration versions
  - Maintains consistency across deployments
*/}}
{{- define "helm-toolkit.podAnnotations" -}}
{{- with .Values.podAnnotations }}
{{- toYaml . }}
{{- end }}
{{- if .Values.configMap }}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}
{{- if .Values.secret }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end }}
{{- end }}
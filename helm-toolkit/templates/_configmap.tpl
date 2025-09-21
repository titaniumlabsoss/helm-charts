{{/*
================================================================================
CONFIGMAP AND SECRET MANAGEMENT HELPERS
================================================================================
This file contains template helpers for managing Kubernetes ConfigMaps and Secrets,
including volume mounts and environment variable configurations.
================================================================================
*/}}

{{/*
helm-toolkit.configMap

Generates a ConfigMap manifest for storing non-sensitive configuration data.
ConfigMaps can be consumed as environment variables, volume mounts, or command arguments.

Usage:
  {{- include "helm-toolkit.configMap" (dict "context" . "component" "api" "name" "app-config" "data" .Values.config) }}

Parameters:
  context (required): The root template context
  component (optional): Component name for labeling (default: "default")
  name (optional): ConfigMap name override (default: fullname-component)
  data (required): Dictionary of configuration data

Returns:
  Complete ConfigMap YAML manifest

Data format:
  All keys and values must be strings. Complex data structures should be
  serialized as YAML or JSON strings.

Example usage:
  {{- $configData := dict
      "app.properties" "debug=true\nport=8080"
      "config.yaml" (.Values.appConfig | toYaml)
      "database.url" "postgresql://localhost:5432/mydb"
  }}
  {{- include "helm-toolkit.configMap" (dict "context" . "data" $configData) }}

Best practices:
  - Use meaningful key names (often filenames)
  - Keep configuration data non-sensitive
  - Use Secrets for sensitive data instead
  - Consider file formats that applications expect
  - Group related configuration together

Common use cases:
  - Application configuration files
  - Database connection parameters (non-sensitive)
  - Feature flags and toggles
  - Environment-specific settings
  - Script files and initialization data

Size limitations:
  - Individual keys: 1MB limit
  - Total ConfigMap: 1MB limit
  - Consider using volumes for large files
*/}}
{{- define "helm-toolkit.configMap" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $configName := .name | default (printf "%s-%s" (include "helm-toolkit.fullname" $context) $component) -}}
{{- $data := .data -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $configName }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
  {{- $annotations := include "helm-toolkit.annotations" $context }}
  {{- if $annotations }}
  annotations:
    {{- $annotations | nindent 4 }}
  {{- end }}
data:
  {{- toYaml $data | nindent 2 }}
{{- end }}

{{/*
helm-toolkit.secret

Generates a Secret manifest for storing sensitive configuration data.
Secrets are base64 encoded and should be used for passwords, tokens, keys, etc.

Usage:
  {{- include "helm-toolkit.secret" (dict "context" . "component" "api" "stringData" .Values.secrets) }}

Parameters:
  context (required): The root template context
  component (optional): Component name for labeling (default: "default")
  name (optional): Secret name override (default: fullname-component)
  data (optional): Dictionary of base64-encoded secret data
  stringData (optional): Dictionary of plain-text secret data (auto-encoded)
  type (optional): Secret type (default: "Opaque")

Returns:
  Complete Secret YAML manifest

Secret types:
  - Opaque: Arbitrary user-defined data (default)
  - kubernetes.io/service-account-token: Service account token
  - kubernetes.io/dockercfg: Docker registry authentication
  - kubernetes.io/dockerconfigjson: Docker registry auth (new format)
  - kubernetes.io/basic-auth: Basic authentication credentials
  - kubernetes.io/ssh-auth: SSH authentication credentials
  - kubernetes.io/tls: TLS certificate and key

Data vs StringData:
  - data: Values must be base64 encoded
  - stringData: Values in plain text (Kubernetes encodes automatically)
  - stringData is preferred for ease of use
  - Both can be used together

Example usage:
  # Using stringData (recommended)
  {{- $secretData := dict
      "database-password" "supersecret123"
      "api-key" "abc123def456"
      "config.json" (.Values.sensitiveConfig | toJson)
  }}
  {{- include "helm-toolkit.secret" (dict "context" . "stringData" $secretData) }}

  # Using pre-encoded data
  {{- $encodedData := dict
      "password" "c3VwZXJzZWNyZXQxMjM="
  }}
  {{- include "helm-toolkit.secret" (dict "context" . "data" $encodedData) }}

Security considerations:
  - Secrets are base64 encoded, not encrypted
  - Use external secret management for production
  - Limit access with RBAC
  - Consider secret rotation policies
  - Never log secret values
  - Use immutable secrets when possible

Best practices:
  - Use descriptive key names
  - Group related secrets together
  - Use external secret operators for production
  - Implement secret rotation
  - Monitor secret access
*/}}
{{- define "helm-toolkit.secret" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $secretName := .name | default (printf "%s-%s" (include "helm-toolkit.fullname" $context) $component) -}}
{{- $data := .data -}}
{{- $stringData := .stringData -}}
{{- $type := .type | default "Opaque" -}}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secretName }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
  {{- $annotations := include "helm-toolkit.annotations" $context }}
  {{- if $annotations }}
  annotations:
    {{- $annotations | nindent 4 }}
  {{- end }}
type: {{ $type }}
{{- if $data }}
data:
  {{- toYaml $data | nindent 2 }}
{{- end }}
{{- if $stringData }}
stringData:
  {{- toYaml $stringData | nindent 2 }}
{{- end }}
{{- end }}

{{/*
helm-toolkit.configMapVolume

Generates a volume definition for mounting a ConfigMap as files in a pod.
Allows selective mounting of specific keys as files with custom permissions.

Usage:
  volumes:
  {{- include "helm-toolkit.configMapVolume" (dict "name" "config" "configMapName" "app-config") | nindent 2 }}

Parameters:
  name (required): Volume name for reference in volumeMounts
  configMapName (required): Name of the ConfigMap to mount
  defaultMode (optional): Default file permissions (default: 420 = 0644)
  items (optional): Array of specific keys to mount with custom paths

Returns:
  Volume definition for use in pod spec

File permissions:
  - 420 (0644): Read-write owner, read-only group/others (default)
  - 365 (0555): Read-execute for all (executable files)
  - 256 (0400): Read-only for owner only (sensitive configs)

Selective mounting with items:
  {{- $items := list
      (dict "key" "app.properties" "path" "application.properties")
      (dict "key" "logging.conf" "path" "conf/logging.conf" "mode" 365)
  }}
  {{- include "helm-toolkit.configMapVolume" (dict
      "name" "config"
      "configMapName" "app-config"
      "items" $items
  ) }}

Common use cases:
  - Application configuration files
  - Scripts and initialization files
  - SSL certificates (non-private)
  - Template files
  - Static web content

Best practices:
  - Use descriptive volume names
  - Set appropriate file permissions
  - Mount only required keys when possible
  - Consider read-only mounts for security
  - Use subPath for single file mounts

Example volume mount:
  volumeMounts:
  - name: config
    mountPath: /etc/config
    readOnly: true
*/}}
{{- define "helm-toolkit.configMapVolume" -}}
{{- $name := .name -}}
{{- $configMapName := .configMapName -}}
{{- $defaultMode := .defaultMode | default 420 -}}
{{- $items := .items -}}
- name: {{ $name }}
  configMap:
    name: {{ $configMapName }}
    defaultMode: {{ $defaultMode }}
    {{- if $items }}
    items:
      {{- toYaml $items | nindent 6 }}
    {{- end }}
{{- end }}

{{/*
helm-toolkit.secretVolume

Generates a volume definition for mounting a Secret as files in a pod.
Provides secure file-based access to sensitive data with proper permissions.

Usage:
  volumes:
  {{- include "helm-toolkit.secretVolume" (dict "name" "certs" "secretName" "tls-secret") | nindent 2 }}

Parameters:
  name (required): Volume name for reference in volumeMounts
  secretName (required): Name of the Secret to mount
  defaultMode (optional): Default file permissions (default: 420 = 0644)
  items (optional): Array of specific keys to mount with custom paths

Returns:
  Volume definition for use in pod spec

Security considerations:
  - Secret volumes are stored in tmpfs (memory)
  - Files are automatically cleaned up when pod terminates
  - More secure than environment variables for sensitive data
  - Supports fine-grained access control

File permissions:
  - 256 (0400): Read-only for owner (recommended for secrets)
  - 384 (0600): Read-write for owner only
  - 420 (0644): Default, but may be too permissive for secrets

Selective mounting with items:
  {{- $items := list
      (dict "key" "tls.crt" "path" "server.crt")
      (dict "key" "tls.key" "path" "server.key" "mode" 256)
  }}
  {{- include "helm-toolkit.secretVolume" (dict
      "name" "tls-certs"
      "secretName" "app-tls"
      "defaultMode" 256
      "items" $items
  ) }}

Common use cases:
  - TLS certificates and private keys
  - Database passwords and connection strings
  - API keys and tokens
  - SSH keys and certificates
  - Application secrets and credentials

Best practices:
  - Use restrictive file permissions (0400 or 0600)
  - Mount secrets read-only when possible
  - Use specific paths to avoid exposing all keys
  - Implement secret rotation
  - Monitor secret access

Example volume mount:
  volumeMounts:
  - name: tls-certs
    mountPath: /etc/ssl/certs
    readOnly: true
*/}}
{{- define "helm-toolkit.secretVolume" -}}
{{- $name := .name -}}
{{- $secretName := .secretName -}}
{{- $defaultMode := .defaultMode | default 420 -}}
{{- $items := .items -}}
- name: {{ $name }}
  secret:
    secretName: {{ $secretName }}
    defaultMode: {{ $defaultMode }}
    {{- if $items }}
    items:
      {{- toYaml $items | nindent 6 }}
    {{- end }}
{{- end }}

{{/*
helm-toolkit.envFromConfigMap

Generates an envFrom entry to load all keys from a ConfigMap as environment variables.
Provides bulk environment variable loading with optional prefixing.

Usage:
  envFrom:
  {{- include "helm-toolkit.envFromConfigMap" (dict "configMapName" "app-config") | nindent 2 }}

Parameters:
  configMapName (required): Name of the ConfigMap to load
  prefix (optional): Prefix to add to all environment variable names

Returns:
  envFrom entry for use in container spec

Environment variable naming:
  - ConfigMap keys become environment variable names
  - Invalid characters are replaced with underscores
  - Keys must follow environment variable naming rules
  - Optional prefix helps avoid naming conflicts

Example with prefix:
  {{- include "helm-toolkit.envFromConfigMap" (dict "configMapName" "db-config" "prefix" "DB_") }}

  # ConfigMap keys: host, port, name
  # Environment variables: DB_host, DB_port, DB_name

Use cases:
  - Loading application configuration
  - Setting feature flags
  - Configuring service endpoints
  - Environment-specific settings

Best practices:
  - Use consistent key naming in ConfigMaps
  - Apply prefixes to avoid variable conflicts
  - Validate environment variable names
  - Group related configuration in single ConfigMap
  - Use descriptive ConfigMap names

Alternatives:
  - Use specific environment variables for sensitive data
  - Consider volume mounts for complex configuration
  - Use init containers for configuration processing
*/}}
{{- define "helm-toolkit.envFromConfigMap" -}}
{{- $configMapName := .configMapName -}}
{{- $prefix := .prefix -}}
- configMapRef:
    name: {{ $configMapName }}
  {{- if $prefix }}
  prefix: {{ $prefix }}
  {{- end }}
{{- end }}

{{/*
helm-toolkit.envFromSecret

Generates an envFrom entry to load all keys from a Secret as environment variables.
Provides secure bulk environment variable loading for sensitive data.

Usage:
  envFrom:
  {{- include "helm-toolkit.envFromSecret" (dict "secretName" "app-secrets") | nindent 2 }}

Parameters:
  secretName (required): Name of the Secret to load
  prefix (optional): Prefix to add to all environment variable names

Returns:
  envFrom entry for use in container spec

Security considerations:
  - Environment variables are visible in process lists
  - Consider volume mounts for highly sensitive data
  - Secrets in environment variables are less secure than files
  - Use specific variable selection when possible

Environment variable naming:
  - Secret keys become environment variable names
  - Invalid characters are replaced with underscores
  - Keys must follow environment variable naming rules
  - Optional prefix helps organize and avoid conflicts

Example with prefix:
  {{- include "helm-toolkit.envFromSecret" (dict "secretName" "auth-secrets" "prefix" "AUTH_") }}

  # Secret keys: username, password, token
  # Environment variables: AUTH_username, AUTH_password, AUTH_token

Common use cases:
  - Database credentials
  - API keys and tokens
  - Authentication secrets
  - Service account credentials

Best practices:
  - Use prefixes to organize secret variables
  - Limit secret exposure to necessary containers
  - Consider using specific env vars for critical secrets
  - Implement secret rotation
  - Monitor for secret leakage
  - Use external secret management for production

Alternatives:
  - Specific environment variables for individual secrets
  - Secret volume mounts for file-based access
  - Init containers for secret processing
  - External secret operators
*/}}
{{- define "helm-toolkit.envFromSecret" -}}
{{- $secretName := .secretName -}}
{{- $prefix := .prefix -}}
- secretRef:
    name: {{ $secretName }}
  {{- if $prefix }}
  prefix: {{ $prefix }}
  {{- end }}
{{- end }}

{{/*
helm-toolkit.envVarFromConfigMap

Generates a single environment variable from a specific ConfigMap key.
Provides precise control over individual configuration values.

Usage:
  env:
  {{- include "helm-toolkit.envVarFromConfigMap" (dict "name" "DB_HOST" "configMapName" "db-config" "key" "host") | nindent 2 }}

Parameters:
  name (required): Environment variable name
  configMapName (required): Name of the ConfigMap
  key (required): Key within the ConfigMap

Returns:
  Single environment variable definition

Advantages over envFrom:
  - Precise control over variable names
  - Can combine multiple ConfigMaps
  - Can selectively expose configuration
  - Better for complex naming requirements

Use cases:
  - Renaming ConfigMap keys to standard environment variables
  - Selecting specific configuration values
  - Combining configuration from multiple sources
  - Standardizing environment variable names

Example combining multiple sources:
  env:
  {{- include "helm-toolkit.envVarFromConfigMap" (dict "name" "DATABASE_URL" "configMapName" "db-config" "key" "url") | nindent 2 }}
  {{- include "helm-toolkit.envVarFromConfigMap" (dict "name" "REDIS_URL" "configMapName" "cache-config" "key" "redis-url") | nindent 2 }}
  {{- include "helm-toolkit.envVarFromSecret" (dict "name" "DB_PASSWORD" "secretName" "db-secret" "key" "password") | nindent 2 }}

Best practices:
  - Use consistent environment variable naming
  - Document the mapping between ConfigMap keys and env vars
  - Validate that referenced keys exist
  - Use meaningful environment variable names
  - Group related variables together
*/}}
{{- define "helm-toolkit.envVarFromConfigMap" -}}
{{- $name := .name -}}
{{- $configMapName := .configMapName -}}
{{- $key := .key -}}
- name: {{ $name }}
  valueFrom:
    configMapKeyRef:
      name: {{ $configMapName }}
      key: {{ $key }}
{{- end }}

{{/*
helm-toolkit.envVarFromSecret

Generates a single environment variable from a specific Secret key.
Provides secure access to individual sensitive configuration values.

Usage:
  env:
  {{- include "helm-toolkit.envVarFromSecret" (dict "name" "DB_PASSWORD" "secretName" "db-secret" "key" "password") | nindent 2 }}

Parameters:
  name (required): Environment variable name
  secretName (required): Name of the Secret
  key (required): Key within the Secret

Returns:
  Single environment variable definition with secret reference

Security considerations:
  - Environment variables are visible in process lists
  - More secure than plain text values
  - Less secure than volume mounts for highly sensitive data
  - Secrets are automatically updated when changed

Advantages over envFrom:
  - Precise control over variable names
  - Can combine multiple Secrets
  - Can selectively expose secrets
  - Better error handling for missing keys

Common patterns:
  # Database credentials
  {{- include "helm-toolkit.envVarFromSecret" (dict "name" "DB_USER" "secretName" "postgres-secret" "key" "username") }}
  {{- include "helm-toolkit.envVarFromSecret" (dict "name" "DB_PASS" "secretName" "postgres-secret" "key" "password") }}

  # API keys
  {{- include "helm-toolkit.envVarFromSecret" (dict "name" "API_KEY" "secretName" "external-api" "key" "key") }}
  {{- include "helm-toolkit.envVarFromSecret" (dict "name" "API_SECRET" "secretName" "external-api" "key" "secret") }}

Use cases:
  - Database passwords and credentials
  - API keys and authentication tokens
  - Encryption keys and certificates
  - Service account credentials
  - Third-party service credentials

Best practices:
  - Use specific environment variable names
  - Validate that secret keys exist
  - Implement secret rotation strategies
  - Monitor for secret exposure
  - Use external secret management for production
  - Consider volume mounts for very sensitive data
*/}}
{{- define "helm-toolkit.envVarFromSecret" -}}
{{- $name := .name -}}
{{- $secretName := .secretName -}}
{{- $key := .key -}}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ $key }}
{{- end }}
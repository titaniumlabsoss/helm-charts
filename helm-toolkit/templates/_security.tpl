{{/*
================================================================================
SECURITY AND COMPLIANCE HELPERS
================================================================================
This file contains template helpers for implementing security best practices,
compliance requirements, and pod security standards.
================================================================================
*/}}

{{/*
helm-toolkit.podSecurityContext

Generates pod-level security context with secure defaults.
Implements defense-in-depth security practices for pod-level controls.

Usage:
  {{- include "helm-toolkit.podSecurityContext" (dict "context" . "component" "api") | nindent 6 }}

Parameters:
  context (required): The root template context
  component (optional): Component name for component-specific settings

Returns:
  Pod security context configuration in YAML format

Configuration:
  .Values.podSecurityContext: Default pod security context
  .Values.podSecurityContext.<component>: Component-specific settings

Secure defaults applied when no configuration provided:
  - runAsNonRoot: true (prevents root execution)
  - runAsUser: 65534 (nobody user)
  - runAsGroup: 65534 (nobody group)
  - fsGroup: 65534 (file system group ownership)
  - seccompProfile.type: RuntimeDefault (syscall filtering)

Security controls:
  - runAsNonRoot: Enforces non-root execution
  - runAsUser/runAsGroup: Specific user/group IDs
  - fsGroup: File system group for volume permissions
  - fsGroupChangePolicy: How group ownership is applied
  - seccompProfile: Seccomp (secure computing) filtering
  - seLinuxOptions: SELinux labeling
  - supplementalGroups: Additional group memberships
  - sysctls: Kernel parameter tuning
  - windowsOptions: Windows-specific settings

Example custom configuration:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 2000
    fsGroupChangePolicy: "OnRootMismatch"
    seccompProfile:
      type: RuntimeDefault
    supplementalGroups: [3000, 4000]
    sysctls:
    - name: "net.core.somaxconn"
      value: "1024"

Compliance considerations:
  - Pod Security Standards: Restricted profile compliance
  - CIS Kubernetes Benchmark: Security hardening
  - NIST guidelines: Defense-in-depth implementation
  - SOC2/ISO27001: Access control requirements

Best practices:
  - Always run as non-root
  - Use specific user/group IDs
  - Enable seccomp filtering
  - Set appropriate fsGroup for volume access
  - Regular security context auditing
*/}}
{{- define "helm-toolkit.podSecurityContext" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $podSecurityContext := index $context.Values "podSecurityContext" $component | default $context.Values.podSecurityContext -}}
{{- if $podSecurityContext }}
securityContext:
  {{- toYaml $podSecurityContext | nindent 2 }}
{{- else }}
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  runAsGroup: 65534
  fsGroup: 65534
  seccompProfile:
    type: RuntimeDefault
{{- end }}
{{- end }}

{{/*
Container Security Context
*/}}
{{- define "helm-toolkit.securityContext" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $securityContext := index $context.Values "securityContext" $component | default $context.Values.securityContext -}}
{{- if $securityContext }}
securityContext:
  {{- toYaml $securityContext | nindent 2 }}
{{- else }}
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65534
  runAsGroup: 65534
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
{{- end }}
{{- end }}

{{/*
Pod Security Standards
*/}}
{{- define "helm-toolkit.podSecurityStandards" -}}
{{- $level := .level | default "restricted" -}}
{{- if eq $level "privileged" }}
pod-security.kubernetes.io/enforce: privileged
pod-security.kubernetes.io/audit: privileged
pod-security.kubernetes.io/warn: privileged
{{- else if eq $level "baseline" }}
pod-security.kubernetes.io/enforce: baseline
pod-security.kubernetes.io/audit: baseline
pod-security.kubernetes.io/warn: baseline
{{- else }}
pod-security.kubernetes.io/enforce: restricted
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
{{- end }}
{{- end }}

{{/*
PodDisruptionBudget
*/}}
{{- define "helm-toolkit.podDisruptionBudget" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $pdb := index $context.Values "podDisruptionBudget" $component | default $context.Values.podDisruptionBudget -}}
{{- if $pdb.enabled }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  {{- if $pdb.minAvailable }}
  minAvailable: {{ $pdb.minAvailable }}
  {{- end }}
  {{- if $pdb.maxUnavailable }}
  maxUnavailable: {{ $pdb.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 6 }}
{{- end }}
{{- end }}

{{/*
Network Security Policy
*/}}
{{- define "helm-toolkit.networkSecurityPolicy" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $policyName := .name | default (printf "%s-%s-security" (include "helm-toolkit.fullname" $context) $component) -}}
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
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: {{ $context.Release.Namespace }}
    - podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: {{ $context.Release.Namespace }}
    - podSelector: {}
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to: []
    ports:
    - protocol: TCP
      port: 443
{{- end }}

{{/*
Container capabilities
*/}}
{{- define "helm-toolkit.capabilities" -}}
{{- $add := .add | default (list) -}}
{{- $drop := .drop | default (list "ALL") -}}
capabilities:
  {{- if $add }}
  add:
    {{- toYaml $add | nindent 4 }}
  {{- end }}
  drop:
    {{- toYaml $drop | nindent 4 }}
{{- end }}

{{/*
Security annotations for enhanced security
*/}}
{{- define "helm-toolkit.securityAnnotations" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $securityConfig := index $context.Values "security" $component | default $context.Values.security -}}
{{- if $securityConfig.enableAppArmor }}
container.apparmor.security.beta.kubernetes.io/{{ $component }}: runtime/default
{{- end }}
{{- if $securityConfig.enableSELinux }}
container.selinux.security.alpha.kubernetes.io/{{ $component }}: "s0:c123,c456"
{{- end }}
{{- end }}
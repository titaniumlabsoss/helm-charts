{{/*
Merge multiple dictionaries
Usage: {{ include "helm-toolkit.merge" (dict "base" .Values.global "override" .Values.local) }}
*/}}
{{- define "helm-toolkit.merge" -}}
{{- $base := .base | default (dict) -}}
{{- $override := .override | default (dict) -}}
{{- toYaml (merge $override $base) -}}
{{- end }}

{{/*
Validate required values
Usage: {{ include "helm-toolkit.validateRequired" (dict "context" . "required" (list "database.host" "database.name")) }}
*/}}
{{- define "helm-toolkit.validateRequired" -}}
{{- $context := .context -}}
{{- $required := .required -}}
{{- range $required }}
  {{- $path := split "." . }}
  {{- $value := $context.Values }}
  {{- range $path }}
    {{- $value = index $value . }}
  {{- end }}
  {{- if not $value }}
    {{- fail (printf "Required value %s is not set" .) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate random string
Usage: {{ include "helm-toolkit.randomString" 16 }}
*/}}
{{- define "helm-toolkit.randomString" -}}
{{- $length := . | default 16 -}}
{{- randAlphaNum $length -}}
{{- end }}

{{/*
Convert string to snake_case
Usage: {{ include "helm-toolkit.toSnakeCase" "MyVariableName" }}
*/}}
{{- define "helm-toolkit.toSnakeCase" -}}
{{- . | lower | replace "-" "_" | replace " " "_" -}}
{{- end }}

{{/*
Convert string to kebab-case
Usage: {{ include "helm-toolkit.toKebabCase" "MyVariableName" }}
*/}}
{{- define "helm-toolkit.toKebabCase" -}}
{{- . | lower | replace "_" "-" | replace " " "-" -}}
{{- end }}

{{/*
Get image pull policy based on tag
Usage: {{ include "helm-toolkit.imagePullPolicy" "latest" }}
*/}}
{{- define "helm-toolkit.imagePullPolicy" -}}
{{- $tag := . -}}
{{- if or (eq $tag "latest") (eq $tag "master") (eq $tag "main") (eq $tag "develop") -}}
Always
{{- else -}}
IfNotPresent
{{- end -}}
{{- end }}

{{/*
Format image reference
Usage: {{ include "helm-toolkit.image" (dict "repository" "nginx" "tag" "1.21" "registry" "docker.io") }}
*/}}
{{- define "helm-toolkit.image" -}}
{{- $registry := .registry | default "" -}}
{{- $repository := .repository -}}
{{- $tag := .tag | default "latest" -}}
{{- $digest := .digest | default "" -}}
{{- if $registry -}}
  {{- $registry }}/{{ $repository }}
{{- else -}}
  {{- $repository }}
{{- end -}}
{{- if $digest -}}
  @{{ $digest }}
{{- else -}}
  :{{ $tag }}
{{- end -}}
{{- end }}

{{/*
Calculate resource requirements based on profile
Usage: {{ include "helm-toolkit.resourceProfile" (dict "profile" "small" "custom" .Values.resources) }}
*/}}
{{- define "helm-toolkit.resourceProfile" -}}
{{- $profile := .profile | default "medium" -}}
{{- $custom := .custom -}}
{{- $profiles := dict
     "nano" (dict "requests" (dict "cpu" "10m" "memory" "32Mi") "limits" (dict "cpu" "50m" "memory" "64Mi"))
     "micro" (dict "requests" (dict "cpu" "25m" "memory" "64Mi") "limits" (dict "cpu" "100m" "memory" "128Mi"))
     "small" (dict "requests" (dict "cpu" "100m" "memory" "128Mi") "limits" (dict "cpu" "200m" "memory" "256Mi"))
     "medium" (dict "requests" (dict "cpu" "200m" "memory" "256Mi") "limits" (dict "cpu" "500m" "memory" "512Mi"))
     "large" (dict "requests" (dict "cpu" "500m" "memory" "512Mi") "limits" (dict "cpu" "1000m" "memory" "1Gi"))
     "xlarge" (dict "requests" (dict "cpu" "1000m" "memory" "1Gi") "limits" (dict "cpu" "2000m" "memory" "2Gi"))
-}}
{{- $defaultResources := index $profiles $profile -}}
{{- if $custom -}}
  {{- toYaml (merge $custom $defaultResources) -}}
{{- else -}}
  {{- toYaml $defaultResources -}}
{{- end -}}
{{- end }}

{{/*
Environment variable from field reference
Usage: {{ include "helm-toolkit.envFieldRef" (dict "name" "POD_IP" "fieldPath" "status.podIP") }}
*/}}
{{- define "helm-toolkit.envFieldRef" -}}
{{- $name := .name -}}
{{- $fieldPath := .fieldPath -}}
- name: {{ $name }}
  valueFrom:
    fieldRef:
      fieldPath: {{ $fieldPath }}
{{- end }}

{{/*
Environment variable from resource field reference
Usage: {{ include "helm-toolkit.envResourceFieldRef" (dict "name" "CPU_LIMIT" "resource" "limits.cpu") }}
*/}}
{{- define "helm-toolkit.envResourceFieldRef" -}}
{{- $name := .name -}}
{{- $resource := .resource -}}
{{- $divisor := .divisor | default "1" -}}
- name: {{ $name }}
  valueFrom:
    resourceFieldRef:
      resource: {{ $resource }}
      divisor: {{ $divisor }}
{{- end }}

{{/*
Wait for dependency helper
Usage: {{ include "helm-toolkit.waitFor" (dict "service" "postgres" "port" 5432) }}
*/}}
{{- define "helm-toolkit.waitFor" -}}
{{- $service := .service -}}
{{- $port := .port -}}
{{- $timeout := .timeout | default 300 -}}
until nc -z {{ $service }} {{ $port }}; do
  echo "Waiting for {{ $service }}:{{ $port }}..."
  sleep 2
done
echo "{{ $service }}:{{ $port }} is ready!"
{{- end }}

{{/*
Init container for dependency waiting
Usage: {{ include "helm-toolkit.initContainer" (dict "name" "wait-db" "image" "busybox:1.35" "command" (include "helm-toolkit.waitFor" (dict "service" "postgres" "port" 5432))) }}
*/}}
{{- define "helm-toolkit.initContainer" -}}
{{- $name := .name -}}
{{- $image := .image | default "busybox:1.35" -}}
{{- $command := .command -}}
- name: {{ $name }}
  image: {{ $image }}
  command:
  - sh
  - -c
  - |
    {{- $command | nindent 4 }}
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    runAsGroup: 65534
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
      - ALL
{{- end }}

{{/*
Volume mount helper
Usage: {{ include "helm-toolkit.volumeMount" (dict "name" "config" "mountPath" "/etc/config" "readOnly" true) }}
*/}}
{{- define "helm-toolkit.volumeMount" -}}
{{- $name := .name -}}
{{- $mountPath := .mountPath -}}
{{- $readOnly := .readOnly | default false -}}
{{- $subPath := .subPath -}}
- name: {{ $name }}
  mountPath: {{ $mountPath }}
  readOnly: {{ $readOnly }}
  {{- if $subPath }}
  subPath: {{ $subPath }}
  {{- end }}
{{- end }}

{{/*
Persistent Volume Claim
Usage: {{ include "helm-toolkit.persistentVolumeClaim" (dict "context" . "component" "data" "size" "10Gi" "storageClass" "fast-ssd") }}
*/}}
{{- define "helm-toolkit.persistentVolumeClaim" -}}
{{- $context := .context -}}
{{- $component := .component | default "data" -}}
{{- $size := .size | default "1Gi" -}}
{{- $storageClass := .storageClass | default "" -}}
{{- $accessModes := .accessModes | default (list "ReadWriteOnce") -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  accessModes:
    {{- toYaml $accessModes | nindent 4 }}
  {{- if $storageClass }}
  storageClassName: {{ $storageClass }}
  {{- end }}
  resources:
    requests:
      storage: {{ $size }}
{{- end }}
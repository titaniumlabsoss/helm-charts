{{/*
Liveness probe configuration
*/}}
{{- define "helm-toolkit.livenessProbe" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $probe := .probe -}}
{{- $probeConfig := index $context.Values "livenessProbe" $component | default $context.Values.livenessProbe | default $probe -}}
{{- if $probeConfig }}
livenessProbe:
  {{- if $probeConfig.httpGet }}
  httpGet:
    path: {{ $probeConfig.httpGet.path | default "/health" }}
    port: {{ $probeConfig.httpGet.port | default "http" }}
    scheme: {{ $probeConfig.httpGet.scheme | default "HTTP" }}
    {{- with $probeConfig.httpGet.httpHeaders }}
    httpHeaders:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- else if $probeConfig.tcpSocket }}
  tcpSocket:
    port: {{ $probeConfig.tcpSocket.port }}
  {{- else if $probeConfig.exec }}
  exec:
    command:
      {{- toYaml $probeConfig.exec.command | nindent 6 }}
  {{- end }}
  initialDelaySeconds: {{ $probeConfig.initialDelaySeconds | default 30 }}
  periodSeconds: {{ $probeConfig.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probeConfig.timeoutSeconds | default 5 }}
  successThreshold: {{ $probeConfig.successThreshold | default 1 }}
  failureThreshold: {{ $probeConfig.failureThreshold | default 3 }}
{{- end }}
{{- end }}

{{/*
Readiness probe configuration
*/}}
{{- define "helm-toolkit.readinessProbe" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $probe := .probe -}}
{{- $probeConfig := index $context.Values "readinessProbe" $component | default $context.Values.readinessProbe | default $probe -}}
{{- if $probeConfig }}
readinessProbe:
  {{- if $probeConfig.httpGet }}
  httpGet:
    path: {{ $probeConfig.httpGet.path | default "/ready" }}
    port: {{ $probeConfig.httpGet.port | default "http" }}
    scheme: {{ $probeConfig.httpGet.scheme | default "HTTP" }}
    {{- with $probeConfig.httpGet.httpHeaders }}
    httpHeaders:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- else if $probeConfig.tcpSocket }}
  tcpSocket:
    port: {{ $probeConfig.tcpSocket.port }}
  {{- else if $probeConfig.exec }}
  exec:
    command:
      {{- toYaml $probeConfig.exec.command | nindent 6 }}
  {{- end }}
  initialDelaySeconds: {{ $probeConfig.initialDelaySeconds | default 5 }}
  periodSeconds: {{ $probeConfig.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probeConfig.timeoutSeconds | default 5 }}
  successThreshold: {{ $probeConfig.successThreshold | default 1 }}
  failureThreshold: {{ $probeConfig.failureThreshold | default 3 }}
{{- end }}
{{- end }}

{{/*
Startup probe configuration
*/}}
{{- define "helm-toolkit.startupProbe" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $probe := .probe -}}
{{- $probeConfig := index $context.Values "startupProbe" $component | default $context.Values.startupProbe | default $probe -}}
{{- if $probeConfig }}
startupProbe:
  {{- if $probeConfig.httpGet }}
  httpGet:
    path: {{ $probeConfig.httpGet.path | default "/health" }}
    port: {{ $probeConfig.httpGet.port | default "http" }}
    scheme: {{ $probeConfig.httpGet.scheme | default "HTTP" }}
    {{- with $probeConfig.httpGet.httpHeaders }}
    httpHeaders:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- else if $probeConfig.tcpSocket }}
  tcpSocket:
    port: {{ $probeConfig.tcpSocket.port }}
  {{- else if $probeConfig.exec }}
  exec:
    command:
      {{- toYaml $probeConfig.exec.command | nindent 6 }}
  {{- end }}
  initialDelaySeconds: {{ $probeConfig.initialDelaySeconds | default 10 }}
  periodSeconds: {{ $probeConfig.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probeConfig.timeoutSeconds | default 5 }}
  successThreshold: {{ $probeConfig.successThreshold | default 1 }}
  failureThreshold: {{ $probeConfig.failureThreshold | default 30 }}
{{- end }}
{{- end }}

{{/*
Metrics annotations for Prometheus scraping
*/}}
{{- define "helm-toolkit.metricsAnnotations" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $metrics := index $context.Values "metrics" $component | default $context.Values.metrics -}}
{{- if and $metrics $metrics.enabled }}
prometheus.io/scrape: "true"
prometheus.io/port: {{ $metrics.port | default "8080" | quote }}
prometheus.io/path: {{ $metrics.path | default "/metrics" | quote }}
{{- if $metrics.scheme }}
prometheus.io/scheme: {{ $metrics.scheme | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Logging configuration
*/}}
{{- define "helm-toolkit.loggingEnv" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $logging := index $context.Values "logging" $component | default $context.Values.logging -}}
{{- if $logging }}
- name: LOG_LEVEL
  value: {{ $logging.level | default "info" | quote }}
- name: LOG_FORMAT
  value: {{ $logging.format | default "json" | quote }}
{{- if $logging.output }}
- name: LOG_OUTPUT
  value: {{ $logging.output | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Telemetry and tracing environment variables
*/}}
{{- define "helm-toolkit.telemetryEnv" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $telemetry := index $context.Values "telemetry" $component | default $context.Values.telemetry -}}
{{- if and $telemetry $telemetry.enabled }}
- name: OTEL_SERVICE_NAME
  value: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
- name: OTEL_SERVICE_VERSION
  value: {{ $context.Chart.AppVersion | default $context.Chart.Version }}
{{- if $telemetry.jaeger }}
- name: OTEL_EXPORTER_JAEGER_ENDPOINT
  value: {{ $telemetry.jaeger.endpoint | quote }}
{{- end }}
{{- if $telemetry.otlp }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ $telemetry.otlp.endpoint | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Grafana dashboard ConfigMap
*/}}
{{- define "helm-toolkit.grafanaDashboard" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $dashboard := .dashboard -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}-dashboard
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
    grafana_dashboard: "1"
  annotations:
    grafana_folder: {{ $context.Values.grafana.folder | default "Titanium Labs" }}
data:
  dashboard.json: |
    {{- $dashboard | toJson | nindent 4 }}
{{- end }}

{{/*
Prometheus rules
*/}}
{{- define "helm-toolkit.prometheusRule" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $rules := .rules -}}
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  groups:
  - name: {{ include "helm-toolkit.fullname" $context }}.{{ $component }}
    rules:
      {{- toYaml $rules | nindent 6 }}
{{- end }}

{{/*
Horizontal Pod Autoscaler
*/}}
{{- define "helm-toolkit.horizontalPodAutoscaler" -}}
{{- $context := .context -}}
{{- $component := .component | default "default" -}}
{{- $hpa := index $context.Values "autoscaling" $component | default $context.Values.autoscaling -}}
{{- if and $hpa $hpa.enabled }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  minReplicas: {{ $hpa.minReplicas | default 1 }}
  maxReplicas: {{ $hpa.maxReplicas | default 10 }}
  metrics:
    {{- if $hpa.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $hpa.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $hpa.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $hpa.targetMemoryUtilizationPercentage }}
    {{- end }}
    {{- with $hpa.customMetrics }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $hpa.behavior }}
  behavior:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
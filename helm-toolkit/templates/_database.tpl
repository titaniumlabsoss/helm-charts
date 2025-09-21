{{/*
Database connection string helper
*/}}
{{- define "helm-toolkit.databaseUrl" -}}
{{- $context := .context -}}
{{- $db := .database -}}
{{- $username := $db.username | default "app" -}}
{{- $password := $db.password | default "password" -}}
{{- $host := $db.host | default "localhost" -}}
{{- $port := $db.port | default 5432 -}}
{{- $name := $db.name | default "app" -}}
{{- $driver := $db.driver | default "postgresql" -}}
{{- if eq $driver "postgresql" -}}
postgresql://{{ $username }}:{{ $password }}@{{ $host }}:{{ $port }}/{{ $name }}
{{- else if eq $driver "mysql" -}}
mysql://{{ $username }}:{{ $password }}@{{ $host }}:{{ $port }}/{{ $name }}
{{- else if eq $driver "mongodb" -}}
mongodb://{{ $username }}:{{ $password }}@{{ $host }}:{{ $port }}/{{ $name }}
{{- else -}}
{{ $driver }}://{{ $username }}:{{ $password }}@{{ $host }}:{{ $port }}/{{ $name }}
{{- end -}}
{{- end }}

{{/*
Database migration job
*/}}
{{- define "helm-toolkit.databaseMigrationJob" -}}
{{- $context := .context -}}
{{- $component := .component | default "migration" -}}
{{- $image := .image -}}
{{- $command := .command | default (list "migrate") -}}
{{- $env := .env | default (list) -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-weight: "-5"
    helm.sh/hook-delete-policy: hook-succeeded
spec:
  template:
    metadata:
      labels:
        {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 8 }}
    spec:
      restartPolicy: Never
      {{- include "helm-toolkit.podSecurityContext" (dict "context" $context "component" $component) | nindent 6 }}
      containers:
      - name: {{ $component }}
        image: {{ $image }}
        command:
          {{- toYaml $command | nindent 10 }}
        {{- include "helm-toolkit.securityContext" (dict "context" $context "component" $component) | nindent 8 }}
        env:
          {{- toYaml $env | nindent 10 }}
        {{- include "helm-toolkit.resources" (dict "context" $context "component" $component) | nindent 8 }}
  backoffLimit: 3
{{- end }}

{{/*
PostgreSQL deployment
*/}}
{{- define "helm-toolkit.postgresql" -}}
{{- $context := .context -}}
{{- $component := .component | default "postgresql" -}}
{{- $image := .image | default "postgres:15-alpine" -}}
{{- $database := .database | default "app" -}}
{{- $username := .username | default "postgres" -}}
{{- $password := .password | default "password" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 8 }}
    spec:
      {{- include "helm-toolkit.podSecurityContext" (dict "context" $context "component" $component) | nindent 6 }}
      containers:
      - name: {{ $component }}
        image: {{ $image }}
        {{- include "helm-toolkit.securityContext" (dict "context" $context "component" $component) | nindent 8 }}
        env:
        - name: POSTGRES_DB
          value: {{ $database }}
        - name: POSTGRES_USER
          value: {{ $username }}
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
              key: password
        ports:
        - containerPort: 5432
          name: postgresql
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        {{- include "helm-toolkit.resources" (dict "context" $context "component" $component) | nindent 8 }}
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - {{ $username }}
            - -d
            - {{ $database }}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - {{ $username }}
            - -d
            - {{ $database }}
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
{{- end }}

{{/*
Redis deployment
*/}}
{{- define "helm-toolkit.redis" -}}
{{- $context := .context -}}
{{- $component := .component | default "redis" -}}
{{- $image := .image | default "redis:7-alpine" -}}
{{- $password := .password | default "" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
  labels:
    {{- include "helm-toolkit.componentLabels" (dict "context" $context "component" $component) | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "helm-toolkit.componentSelectorLabels" (dict "context" $context "component" $component) | nindent 8 }}
    spec:
      {{- include "helm-toolkit.podSecurityContext" (dict "context" $context "component" $component) | nindent 6 }}
      containers:
      - name: {{ $component }}
        image: {{ $image }}
        {{- include "helm-toolkit.securityContext" (dict "context" $context "component" $component) | nindent 8 }}
        {{- if $password }}
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "helm-toolkit.fullname" $context }}-{{ $component }}
              key: password
        {{- end }}
        ports:
        - containerPort: 6379
          name: redis
        {{- include "helm-toolkit.resources" (dict "context" $context "component" $component) | nindent 8 }}
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 5
          periodSeconds: 5
{{- end }}

{{/*
Message queue environment variables
*/}}
{{- define "helm-toolkit.messageQueueEnv" -}}
{{- $context := .context -}}
{{- $mq := .messageQueue -}}
{{- $type := $mq.type | default "rabbitmq" -}}
{{- if eq $type "rabbitmq" }}
- name: RABBITMQ_URL
  value: "amqp://{{ $mq.username | default "guest" }}:{{ $mq.password | default "guest" }}@{{ $mq.host | default "rabbitmq" }}:{{ $mq.port | default 5672 }}/{{ $mq.vhost | default "/" }}"
{{- else if eq $type "kafka" }}
- name: KAFKA_BROKERS
  value: "{{ $mq.host | default "kafka" }}:{{ $mq.port | default 9092 }}"
{{- else if eq $type "nats" }}
- name: NATS_URL
  value: "nats://{{ $mq.host | default "nats" }}:{{ $mq.port | default 4222 }}"
{{- end }}
{{- end }}
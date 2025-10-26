{{/*
Expand the name of the chart.
*/}}
{{- define "kube-state-metrics.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kube-state-metrics.fullname" -}}
  {{- if .Values.fullnameOverride -}}
      {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kube-state-metrics.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kube-state-metrics.labels" }}
helm.sh/chart: {{ template "kube-state-metrics.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: metrics
app.kubernetes.io/part-of: {{ template "kube-state-metrics.name" . }}
{{- include "kube-state-metrics.selectorLabels" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kube-state-metrics.selectorLabels" }}
app.kubernetes.io/name: {{ include "kube-state-metrics.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kube-state-metrics.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
    {{ default (include "kube-state-metrics.fullname" .) .Values.serviceAccount.name }}
  {{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
  {{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "kube-state-metrics.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
kube-state-metrics.podSecurityContext: Returns the pod security context
*/}}
{{- define "kube-state-metrics.podSecurityContext" -}}
  {{- if .Values.podSecurityContext -}}
    {{- with .Values.podSecurityContext }}
      {{- if .enabled }}
        fsGroup: {{ .fsGroup | default 1000 }}
        runAsGroup: {{ .runAsGroup | default 1000 }}
        runAsNonRoot: {{ .runAsNonRoot | default true }}
        runAsUser: {{ .runAsUser | default 1000 }}
        {{- if .fsGroupChangePolicy }}
        fsGroupChangePolicy: {{ .fsGroupChangePolicy }}
        {{- end }}
        {{- if .seccompProfile }}
        seccompProfile:
          {{ toYaml .seccompProfile | nindent 2 }}
        {{- end }}
      {{- else }}
        {{- /* Fallback to securityContext for backward compatibility */}}
        {{- if .Values.securityContext }}
          fsGroup: {{ .Values.securityContext.fsGroup | default 65534 }}
          runAsGroup: {{ .Values.securityContext.runAsGroup | default 65534 }}
          runAsNonRoot: {{ .Values.securityContext.runAsNonRoot | default true }}
          runAsUser: {{ .Values.securityContext.runAsUser | default 65534 }}
        {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
kube-state-metrics.containerSecurityContext: Returns the container security context
*/}}
{{- define "kube-state-metrics.containerSecurityContext" -}}
  {{- if .Values.containerSecurityContext -}}
    {{- with .Values.containerSecurityContext }}
      {{- if .enabled }}
        allowPrivilegeEscalation: {{ .allowPrivilegeEscalation | default false }}
        readOnlyRootFilesystem: {{ .readOnlyRootFilesystem | default true }}
        runAsNonRoot: {{ .runAsNonRoot | default true }}
        runAsUser: {{ .runAsUser | default 1000 }}
        {{- if .capabilities }}
        capabilities:
        {{ toYaml .capabilities | nindent 2 }}
        {{- else }}
        capabilities:
          drop:
          - ALL
        {{- end }}
        {{- if .seccompProfile }}
        seccompProfile:
        {{ toYaml .seccompProfile | nindent 2 }}
        {{- end }}
      {{- end }}
    {{- else }}
      {{- /* Fallback values */}}
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 65534
      capabilities:
        drop:
        - ALL
    {{- end }}
{{- end }}

{{/*
Formats imagePullSecrets. Input is (dict "Values" .Values "imagePullSecrets" .{specific imagePullSecrets})
*/}}
{{- define "kube-state-metrics.imagePullSecrets" -}}
  {{- range .imagePullSecrets }}
    {{- if eq (typeOf .) "map[string]interface {}" }}
  - {{ toYaml . | trim }}
    {{- else }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
The image to use for kube-state-metrics
*/}}
{{- define "kube-state-metrics.image" -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) }}
{{- end }}

{{/*
The image to use for kubeRBACProxy
*/}}
{{- define "kubeRBACProxy.image" -}}
{{- printf "%s/%s:%s" .Values.kubeRBACProxy.image.registry .Values.kubeRBACProxy.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.kubeRBACProxy.image.tag) }}
{{- end }}

{{/*
Sets default scrape limits for servicemonitor
*/}}
{{- define "servicemonitor.scrapeLimits" -}}
  {{- with .sampleLimit }}
  sampleLimit: {{ . }}
  {{- end }}
  {{- with .targetLimit }}
  targetLimit: {{ . }}
  {{- end }}
  {{- with .labelLimit }}
  labelLimit: {{ . }}
  {{- end }}
  {{- with .labelNameLengthLimit }}
  labelNameLengthLimit: {{ . }}
  {{- end }}
  {{- with .labelValueLengthLimit }}
  labelValueLengthLimit: {{ . }}
  {{- end }}
{{- end -}}

{{/*
Sets default scrape limits for scrapeconfig
*/}}
{{- define "scrapeconfig.scrapeLimits" -}}
  {{- with .sampleLimit }}
  sampleLimit: {{ . }}
  {{- end }}
  {{- with .targetLimit }}
  targetLimit: {{ . }}
  {{- end }}
  {{- with .labelLimit }}
  labelLimit: {{ . }}
  {{- end }}
  {{- with .labelNameLengthLimit }}
  labelNameLengthLimit: {{ . }}
  {{- end }}
  {{- with .labelValueLengthLimit }}
  labelValueLengthLimit: {{ . }}
  {{- end }}
{{- end -}}

{{/*
Return the proper Prometheus Scrape Annotations
*/}}
{{- define "kube-state-metrics.prometheusScrapeAnnotations" -}}
  {{- if .Values.prometheusScrape.enabled }}
    {{- range $key, $value := .Values.prometheusScrape.annotations }}
      {{ $key }}: {{ tpl $value $ | quote }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Return the proper Prometheus Scrape Labels
*/}}
{{- define "kube-state-metrics.prometheusScrapeLabels" -}}
  {{- if .Values.prometheusScrape.enabled }}
  {{- with .Values.prometheusScrape.labels }}
    {{- toYaml . }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
The name of the ConfigMap for the customResourceState config.
*/}}
{{- define "kube-state-metrics.crsConfigMapName" -}}
  {{- if ne .Values.customResourceState.name "" }}
    {{- .Values.customResourceState.name }}
  {{- else }}
    {{- template "kube-state-metrics.fullname" . }}-customresourcestate-config
  {{- end }}
{{- end }}

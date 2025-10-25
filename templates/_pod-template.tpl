{{/*
Common pod template for both Deployment and StatefulSet
*/}}
{{- define "kube-state-metrics.podTemplate" -}}
metadata:
  labels:
    {{- include "kube-state-metrics.selectorLabels" . | nindent 4 }}
    {{- with .Values.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- include "kube-state-metrics.prometheusScrapeLabels" . | nindent 4 }}
  annotations:
    {{- include "kube-state-metrics.prometheusScrapeAnnotations" . | nindent 4 }}
    {{- with .Values.podAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if .Values.serviceAccount.create }}
  serviceAccountName: {{ include "kube-state-metrics.serviceAccountName" . }}
  {{- end }}
  automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
  
  # Security Context
  {{- include "kube-state-metrics.podSecurityContext" . | nindent 2 }}
  
  # Image Pull Secrets
  {{- include "kube-state-metrics.imagePullSecrets" . | nindent 2 }}
  
  # Host configurations
  hostNetwork: {{ .Values.hostNetwork }}
  {{- if .Values.dnsPolicy }}
  dnsPolicy: {{ .Values.dnsPolicy }}
  {{- end }}
  {{- with .Values.dnsConfig }}
  dnsConfig:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  
  # Priority Class
  {{- include "kube-state-metrics.priorityClassName" . | nindent 2 }}
  
  # Init Containers
  {{- with .Values.initContainers }}
  initContainers:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  
  # Main Container(s)
  containers:
    # kube-state-metrics main container
    - name: {{ .Chart.Name }}
      image: {{ include "kube-state-metrics.image" . }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      
      # Security Context
      {{- include "kube-state-metrics.containerSecurityContext" . | nindent 6 }}
      
      # Environment Variables
      env:
        {{- if .Values.autosharding.enabled }}
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        {{- end }}
        {{- with .Values.extraEnv }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      
      # Ports
      ports:
        - name: http-metrics
          containerPort: {{ .Values.service.port }}
          protocol: TCP
        {{- if .Values.selfMonitor.enabled }}
        - name: http-telemetry
          containerPort: {{ .Values.service.telemetryPort }}
          protocol: TCP
        {{- end }}
      
      # Arguments
      args:
        - --port={{ .Values.service.port }}
        {{- if .Values.selfMonitor.enabled }}
        - --telemetry-port={{ .Values.service.telemetryPort }}
        {{- end }}
        - --metrics-path={{ .Values.service.metricsPath }}
        {{- if .Values.collectors }}
        - --collectors={{ join "," .Values.collectors }}
        {{- end }}
        {{- if .Values.resources }}
        - --resources={{ join "," .Values.resources }}
        {{- end }}
        {{- if .Values.namespaces }}
        - --namespaces={{ join "," .Values.namespaces }}
        {{- end }}
        {{- if .Values.namespace }}
        - --namespace={{ .Values.namespace }}
        {{- end }}
        {{- if .Values.autosharding.enabled }}
        - --pod=$(POD_NAME)
        - --pod-namespace=$(POD_NAMESPACE)
        {{- end }}
        {{- range $key, $value := .Values.extraArgs }}
        - --{{ $key }}={{ $value }}
        {{- end }}
      
      # Probes
      livenessProbe:
        {{- toYaml .Values.livenessProbe | nindent 8 }}
      readinessProbe:
        {{- toYaml .Values.readinessProbe | nindent 8 }}
      {{- if .Values.startupProbe.enabled }}
      startupProbe:
        {{- toYaml .Values.startupProbe | nindent 8 }}
      {{- end }}
      
      # Resources
      resources:
        {{- toYaml .Values.resources | nindent 8 }}
      
      # Volume Mounts
      volumeMounts:
        {{- if .Values.kubeconfig.enabled }}
        - name: kubeconfig
          mountPath: /root/.kube
          readOnly: true
        {{- end }}
        {{- with .Values.extraVolumeMounts }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    
    # kubeRBACProxy container (if enabled)
    {{- if .Values.kubeRBACProxy.enabled }}
    - name: kube-rbac-proxy
      image: {{ include "kube-state-metrics.kubeRBACProxyImage" . }}
      imagePullPolicy: {{ .Values.kubeRBACProxy.image.pullPolicy }}
      args:
        - --secure-listen-address=0.0.0.0:8443
        - --upstream=http://127.0.0.1:{{ .Values.service.port }}/
        - --logtostderr=true
        - --v=2
      ports:
        - name: https
          containerPort: 8443
          protocol: TCP
      resources:
        {{- toYaml .Values.kubeRBACProxy.resources | nindent 8 }}
      {{- if .Values.kubeRBACProxy.securityContext }}
      securityContext:
        {{- toYaml .Values.kubeRBACProxy.securityContext | nindent 8 }}
      {{- end }}
    {{- end }}
  
  # Volumes
  volumes:
    {{- if .Values.kubeconfig.enabled }}
    - name: kubeconfig
      secret:
        secretName: {{ .Values.kubeconfig.secretName }}
    {{- end }}
    {{- with .Values.extraVolumes }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  
  # Scheduling
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.topologySpreadConstraints }}
  topologySpreadConstraints:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
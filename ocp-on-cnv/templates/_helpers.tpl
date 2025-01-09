{{- define "my-helm-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "my-helm-chart.labels" -}}
app: {{ include "my-helm-chart.fullname" . }}
environment: {{ .Values.common.metadata.labels.environment }}
owner: {{ .Values.common.metadata.labels.owner }}
demo: {{ .Values.common.metadata.labels.demo }}
{{- end -}}

{{- define "my-helm-chart.annotations" -}}
{{- range $key, $value := .Values.common.metadata.annotations }}
{{ $key }}: {{ $value }}
{{- end }}
{{- end -}}
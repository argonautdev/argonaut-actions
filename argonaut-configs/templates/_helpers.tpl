{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "argonaut-deployment.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define image name for use. Prioritizes imageDigest
Falling back to imageTag, and defaulting to "latest"
*/}}
{{- define "argonaut-deployment.imageName" -}}
{{- if empty .Values.imageDigest -}}
{{- if empty .Values.imageTag -}}
{{- .Values.image -}}:latest
{{- else -}}
{{- .Values.image -}}:{{- .Values.imageTag -}}
{{- end -}}
{{- else -}}
{{- .Values.image -}}@{{- .Values.imageDigest -}}
{{- end -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "argonaut-deployment.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "argonaut-deployment.uname" -}}
{{- if empty .Values.nameOverride -}}
{{ .Values.appName }}
{{- else -}}
{{ .Values.nameOverride }}
{{- end -}}
{{- end -}}

{{- define "argonaut-deployment.endpoints" -}}
{{- $replicas := int (toString (.Values.replicas)) }}
{{- $uname := (include "argonaut-deployment.uname" .) }}
  {{- range $i, $e := untilStep 0 $replicas 1 -}}
{{ $uname }}-{{ $i }},
  {{- end -}}
{{- end -}}

{{- define "nomad.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "nomad.fullname" -}}
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

{{- define "nomad.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "nomad.labels" -}}
helm.sh/chart: {{ include "nomad.chart" . }}
{{ include "nomad.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "nomad.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nomad.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nomad.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nomad.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "nomad.config" -}}
{{- .Values.nomad.config }}
{{- end }}

{{- define "nomad.config.apiHost" -}}
{{- .Values.nomad.config.services.api_host }}
{{- end }}

{{- define "nomad.config.apiBasePath" -}}
{{- .Values.nomad.config.services.api_base_path }}
{{- end }}

{{- define "nomad.config.https" -}}
{{- .Values.nomad.config.services.https }}
{{- end }}

{{- define "nomad.secretName.api" -}}
{{- if .Values.nomad.secrets.api.existingSecret }}
{{- .Values.nomad.secrets.api.existingSecret }}
{{- else }}
{{- printf "%s-api-secret" (include "nomad.fullname" .) }}
{{- end }}
{{- end }}

{{- define "nomad.secretName.keycloakClient" -}}
{{- if .Values.nomad.secrets.keycloak.clientSecret.existingSecret }}
{{- .Values.nomad.secrets.keycloak.clientSecret.existingSecret }}
{{- else }}
{{- printf "%s-keycloak-client-secret" (include "nomad.fullname" .) }}
{{- end }}
{{- end }}

{{- define "nomad.secretName.keycloakPassword" -}}
{{- if .Values.nomad.secrets.keycloak.password.existingSecret }}
{{- .Values.nomad.secrets.keycloak.password.existingSecret }}
{{- else }}
{{- printf "%s-keycloak-password-secret" (include "nomad.fullname" .) }}
{{- end }}
{{- end }}

{{- define "nomad.secretName.north" -}}
{{- if .Values.nomad.secrets.north.hubServiceApiToken.existingSecret }}
{{- .Values.nomad.secrets.north.hubServiceApiToken.existingSecret }}
{{- else }}
{{- printf "%s-north-hub-token-secret" (include "nomad.fullname" .) }}
{{- end }}
{{- end }}

{{- define "nomad.hasApiSecret" -}}
{{- or .Values.nomad.secrets.api.existingSecret .Values.nomad.secrets.api.value .Values.nomad.secrets.api.autoGenerate }}
{{- end }}

{{- define "nomad.validateConfig" -}}
{{- $config := .Values.nomad.config -}}
{{- $warnings := list -}}

{{- if and $config.temporal.enabled (not .Values.temporal.enabled) }}
{{- $warnings = append $warnings "temporal is enabled in nomad.config but temporal subchart is disabled" }}
{{- end }}

{{- if and $config.north.enabled (not .Values.jupyterhub.enabled) }}
{{- $warnings = append $warnings "north is enabled in nomad.config but jupyterhub is disabled" }}
{{- end }}

{{- if and (not .Values.nomad.secrets.api.existingSecret) (not .Values.nomad.secrets.api.value) (not .Values.nomad.secrets.api.autoGenerate) }}
{{- $warnings = append $warnings "No API secret configured - set nomad.secrets.api.existingSecret, .value, or .autoGenerate" }}
{{- end }}

{{- $warnings | toJson }}
{{- end }}

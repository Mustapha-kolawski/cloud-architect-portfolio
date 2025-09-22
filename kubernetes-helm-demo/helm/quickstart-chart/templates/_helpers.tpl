
{{- define "quickstart-chart.name" -}}
quickstart
{{- end -}}
{{- define "quickstart-chart.fullname" -}}
{{ include "quickstart-chart.name" . }}-svc
{{- end -}}

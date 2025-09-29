{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/*
Return the proper Strimzi Kafka Operator image name
*/}}
{{- define "strimzi.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Strimzi Kafka image name
*/}}
{{- define "strimzi.kafka.image" -}}
{{- $imageRoot := index .context.Values.kafkaImages .version -}}
{{- include "common.images.image" (dict "imageRoot" $imageRoot "global" .context.Values.global) -}}
{{- end -}}

{{/*
Return the proper Strimzi Kafka Bridge image name
*/}}
{{- define "strimzi.kafkaBridge.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.kafkaBridgeImage "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Kaniko Executor image name
*/}}
{{- define "strimzi.kaniko.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.kanikoImage "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "strimzi.imagePullSecrets" -}}
{{- $kafka400 := index .Values.kafkaImages "4.0.0" -}}
{{- $kafka410 := index .Values.kafkaImages "4.1.0" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.image $kafka400 $kafka410 .Values.kafkaBridgeImage .Values.kanikoImage) "context" .) -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "strimzi.checkRollingTags" -}}
{{- $kafka400 := index .Values.kafkaImages "4.0.0" -}}
{{- $kafka410 := index .Values.kafkaImages "4.1.0" -}}
{{- include "common.warnings.rollingTag" .Values.image }}
{{- include "common.warnings.rollingTag" $kafka400 }}
{{- include "common.warnings.rollingTag" $kafka410 }}
{{- include "common.warnings.rollingTag" .Values.kafkaBridgeImage }}
{{- include "common.warnings.rollingTag" .Values.kanikoImage }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names as a comma separated string
*/}}
{{- define "strimzi.imagePullSecrets.string" -}}
{{- $pullSecrets := list }}
{{- range ((.Values.global).imagePullSecrets) -}}
  {{- $pullSecrets = append $pullSecrets . -}}
{{- end -}}
{{- $kafka400 := index .Values.kafkaImages "4.0.0" -}}
{{- $kafka410 := index .Values.kafkaImages "4.1.0" -}}
{{- range (list .Values.image $kafka400 $kafka410 .Values.kafkaBridgeImage .Values.kanikoImage) -}}
  {{- range .pullSecrets -}}
    {{- $pullSecrets = append $pullSecrets . -}}
  {{- end -}}
{{- end -}}
{{- if (not (empty $pullSecrets)) }}
  {{- printf "%s" (join "," $pullSecrets) -}}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "strimzi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the Strimzi Kafka Operator configuration configmap
*/}}
{{- define "strimzi.configmap.name" -}}
{{- if .Values.existingLogConfigmap -}}
    {{- print (tpl .Values.existingLogConfigmap $) -}}
{{- else -}}
    {{- print (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

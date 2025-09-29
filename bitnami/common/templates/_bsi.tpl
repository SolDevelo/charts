{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Is Bitnami Secure Images catalogue enabled?
{{ include "common.bsi.enabled" . }}
*/}}
{{- define "common.bsi.enabled" -}}
    {{- $bsi := .Chart.Annotations.bsi -}}
    {{- if eq "true" $bsi -}}
        {{- true -}}
    {{- end -}}
{{- end -}}

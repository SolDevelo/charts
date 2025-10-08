{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{- define "temporal.frontend.fullname" -}}
{{- printf "%s-frontend" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "temporal.history.fullname" -}}
{{- printf "%s-history" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "temporal.matching.fullname" -}}
{{- printf "%s-matching" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "temporal.worker.fullname" -}}
{{- printf "%s-worker" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "temporal.web.fullname" -}}
{{- printf "%s-web" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "temporal.postgresql.default.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "pg-default" "chartValues" .Values.pgDefault "context" .) -}}
{{- end -}}

{{- define "temporal.postgresql.visibility.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "pg-visibility" "chartValues" .Values.pgVisibility "context" .) -}}
{{- end -}}

{{/*
Return the proper Temporal image name
*/}}
{{- define "temporal.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Temporal UI image name
*/}}
{{- define "temporal.web.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.web.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper "wait-for-db" init-container image name
*/}}
{{- define "temporal.waitForDB.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.defaultInitContainers.waitForDB.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "temporal.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.image .Values.web.image .Values.defaultInitContainers.waitForDB.image) "context" .) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "temporal.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get the Temporal ConfigMap name
*/}}
{{- define "temporal.configMapName" -}}
{{- if .Values.existingConfigmap -}}
    {{- print (tpl .Values.existingConfigmap .) -}}
{{- else -}}
    {{- print (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the default database hostname
*/}}
{{- define "temporal.database.default.host" -}}
{{- if .Values.pgDefault.enabled -}}
    {{- if eq .Values.pgDefault.architecture "replication" -}}
        {{- printf "%s-primary" (include "temporal.postgresql.default.fullname" .) | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- print (include "temporal.postgresql.default.fullname" .) -}}
    {{- end -}}
{{- else -}}
    {{- print .Values.externalDatabaseDefault.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the visibility database hostname
*/}}
{{- define "temporal.database.visibility.host" -}}
{{- if .Values.useDefaultDbServerForVisibility -}}
    {{- include "temporal.database.default.host" . -}}
{{- else if .Values.pgVisibility.enabled -}}
    {{- if eq .Values.pgVisibility.architecture "replication" -}}
        {{- printf "%s-primary" (include "temporal.postgresql.visibility.fullname" .) | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- print (include "temporal.postgresql.visibility.fullname" .) -}}
    {{- end -}}
{{- else -}}
    {{- print .Values.externalDatabaseVisibility.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the default database port
*/}}
{{- define "temporal.database.default.port" -}}
{{- if .Values.pgDefault.enabled -}}
    {{- print "5432" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabaseDefault.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the visibility database port
*/}}
{{- define "temporal.database.visibility.port" -}}
{{- if .Values.useDefaultDbServerForVisibility -}}
    {{- include "temporal.database.default.port" . -}}
{{- else if .Values.pgVisibility.enabled -}}
    {{- print "5432" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabaseVisibility.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the default database name
*/}}
{{- define "temporal.database.default.name" -}}
{{- if .Values.pgDefault.enabled -}}
    {{- coalesce .Values.pgDefault.auth.database "postgres" -}}
{{- else -}}
    {{- tpl .Values.externalDatabaseDefault.database . -}}
{{- end -}}
{{- end -}}

{{/*
Return the visibility database name
*/}}
{{- define "temporal.database.visibility.name" -}}
{{- if .Values.useDefaultDbServerForVisibility -}}
    {{- coalesce .Values.pgDefault.auth.visibilityDatabase "postgres" -}}
{{- else if .Values.pgVisibility.enabled -}}
    {{- coalesce .Values.pgVisibility.auth.database "postgres" -}}
{{- else -}}
    {{- tpl .Values.externalDatabaseVisibility.database . -}}
{{- end -}}
{{- end -}}

{{/*
Return the default database username
*/}}
{{- define "temporal.database.default.username" -}}
{{- if .Values.pgDefault.enabled -}}
    {{- .Values.pgDefault.auth.username | default "" -}}
{{- else -}}
    {{- tpl .Values.externalDatabaseDefault.username . -}}
{{- end -}}
{{- end -}}

{{/*
Return the visibility database username
*/}}
{{- define "temporal.database.visibility.username" -}}
{{- if .Values.useDefaultDbServerForVisibility -}}
    {{- include "temporal.database.default.username" . -}}
{{- else if .Values.pgVisibility.enabled -}}
    {{- .Values.pgVisibility.auth.username | default "" -}}
{{- else -}}
    {{- tpl .Values.externalDatabaseVisibility.username . -}}
{{- end -}}
{{- end -}}

{{/*
Return the default database secret name
*/}}
{{- define "temporal.database.default.secretName" -}}
{{- if .Values.pgDefault.enabled -}}
    {{- if not (empty (.Values.pgDefault.auth.existingSecret | default "")) -}}
        {{- tpl (.Values.pgDefault.auth.existingSecret) . -}}
    {{- else -}}
        {{- include "temporal.postgresql.default.fullname" . -}}
    {{- end -}}
{{- else if not (empty .Values.externalDatabaseDefault.existingSecret) -}}
    {{- print (tpl .Values.externalDatabaseDefault.existingSecret .) -}}
{{- else -}}
    {{- printf "%s-default-externaldb" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the visibility database secret name
*/}}
{{- define "temporal.database.visibility.secretName" -}}
{{- if .Values.useDefaultDbServerForVisibility -}}
    {{- include "temporal.database.default.secretName" . -}}
{{- else if .Values.pgVisibility.enabled -}}
    {{- if not (empty (.Values.pgVisibility.auth.existingSecret | default "")) -}}
        {{- tpl (.Values.pgVisibility.auth.existingSecret) . -}}
    {{- else -}}
        {{- include "temporal.postgresql.visibility.fullname" . -}}
    {{- end -}}
{{- else if not (empty .Values.externalDatabaseVisibility.existingSecret) -}}
    {{- print (tpl .Values.externalDatabaseVisibility.existingSecret .) -}}
{{- else -}}
    {{- printf "%s-visibility-externaldb" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret key that contains the default database password
*/}}
{{- define "temporal.database.default.secretPasswordKey" -}}
{{- if .Values.pgDefault.enabled -}}
    {{- default "password" .Values.pgDefault.auth.secretKeys.userPasswordKey -}}
{{- else if .Values.externalDatabaseDefault.existingSecret -}}
    {{- default "db-password" .Values.externalDatabaseDefault.existingSecretPasswordKey -}}
{{- else -}}
    {{- print "db-password" -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret key that contains the visibility database password
*/}}
{{- define "temporal.database.visibility.secretPasswordKey" -}}
{{- if .Values.useDefaultDbServerForVisibility -}}
    {{- include "temporal.database.default.secretPasswordKey" . -}}
{{- else if .Values.pgVisibility.enabled -}}
    {{- default "password" .Values.pgVisibility.auth.secretKeys.userPasswordKey -}}
{{- else if .Values.externalDatabaseVisibility.existingSecret -}}
    {{- default "db-password" .Values.externalDatabaseVisibility.existingSecretPasswordKey -}}
{{- else -}}
    {{- print "db-password" -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the CA TLS certificate
*/}}
{{- define "temporal.tls.ca.secretName" -}}
{{- if and (not .Values.tls.autoGenerated.enabled) (empty .Values.tls.ca) -}}
    {{- required "An existing secret name must be provided with a CA cert for Temporal if cert is not provided!" (tpl .Values.tls.existingCASecret .) -}}
{{- end -}}
{{/* We don't return anything otherwise, given the secrets already contain the CA */}}
{{- end -}}

{{/*
Return the name of the secret containing the TLS certificates for Temporal internode communications
*/}}
{{- define "temporal.tls.internode.secretName" -}}
{{- if or .Values.tls.autoGenerated.enabled (and (not (empty .Values.tls.internode.cert)) (not (empty .Values.tls.internode.key))) -}}
    {{- printf "%s-internode-crt" (include "common.names.fullname" .) -}}
{{- else -}}
    {{- required "An existing secret name must be provided with TLS certs for Temporal internode communications if cert and key are not provided!" (tpl .Values.tls.internode.existingSecret .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the TLS certificates for Temporal frontend-to-client communications
*/}}
{{- define "temporal.tls.frontend.secretName" -}}
{{- if or .Values.tls.autoGenerated.enabled (and (not (empty .Values.tls.frontend.cert)) (not (empty .Values.tls.frontend.key))) -}}
    {{- printf "%s-crt" (include "temporal.frontend.fullname" .) -}}
{{- else -}}
    {{- required "An existing secret name must be provided with TLS certs for Temporal frontend-to-client communications if cert and key are not provided!" (tpl .Values.tls.frontend.existingSecret .) -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "temporal.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "temporal.validateValues.database" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Temporal - database */}}
{{- define "temporal.validateValues.database" -}}
{{- if and .Values.pgDefault.enabled (not .Values.externalDatabaseDefault.host) -}}
temporal: default store
    You disabled the PostgreSQL sub-chart but did not specify an external PostgreSQL host.
    Either deploy the PostgreSQL sub-chart (--set pgDefault.enabled=true),
    or set a value for the external database host (--set externalDatabaseDefault.host=FOO)
    and set a value for the external database password (--set externalDatabaseDefault.password=BAR)
    or existing secret (--set externalDatabaseDefault.existingSecret=BAR).
{{- end -}}
{{- if and .Values.pgVisibility.enabled (not .Values.externalDatabaseVisibility.host) -}}
temporal: visibility store
    You disabled the PostgreSQL sub-chart but did not specify an external PostgreSQL host.
    Either deploy the PostgreSQL sub-chart (--set pgVisibility.enabled=true),
    or set a value for the external database host (--set externalDatabaseVisibility.host=FOO)
    and set a value for the external database password (--set externalDatabaseVisibility.password=BAR)
    or existing secret (--set externalDatabaseVisibility.existingSecret=BAR).
{{- end -}}
{{- if and .Values.useDefaultDbServerForVisibility .Values.pgVisibility.enabled -}}
temporal: visibility store
    You cannot use reuse the default database server for the visibility store if you are deploying a
    separate PostgreSQL instance for the visibility store. Either disable reusing the default database server
    (--set useDefaultDbServerForVisibility=false) or disable the PostgreSQL sub-chart for the visibility store
    (--set pgVisibility.enabled=false).
{{- end -}}
{{- end -}}

{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Returns an init-container that waits for db to be ready
*/}}
{{- define "temporal.defaultInitContainers.waitForDB" -}}
- name: wait-for-db
  image: {{ include "temporal.waitForDB.image" .context }}
  imagePullPolicy: {{ .context.Values.defaultInitContainers.waitForDB.image.pullPolicy | quote }}
  {{- if .context.Values.defaultInitContainers.waitForDB.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .context.Values.defaultInitContainers.waitForDB.containerSecurityContext "context" .context) | nindent 4 }}
  {{- end }}
  {{- if .context.Values.defaultInitContainers.waitForDB.resources }}
  resources: {{- toYaml .context.Values.defaultInitContainers.waitForDB.resources | nindent 4 }}
  {{- else if ne .context.Values.defaultInitContainers.waitForDB.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .context.Values.defaultInitContainers.waitForDB.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
      . /opt/bitnami/scripts/liblog.sh
      . /opt/bitnami/scripts/libos.sh

      {{- if .context.Values.usePasswordFiles }}
      export DATABASE_PASSWORD="$(< $DATABASE_PASSWORD_FILE)"
      {{- end }}

      info "Waiting for host $DATABASE_HOST"
      postgresql_is_ready() {
          if [[ $(PGPASSWORD="$DATABASE_PASSWORD" psql -w -U "$DATABASE_USER" -d "$DATABASE_NAME" -h "$DATABASE_HOST" -p "$DATABASE_PORT_NUMBER" -tA -c "$DATABASE_READY_QUERY" 2> /dev/null || true) = 1 ]]; then
              return 0
          fi
          return 1
      }
      if ! retry_while "postgresql_is_ready"; then
          error "Database not ready"
          exit 1
      fi
      info "Database is ready"
  env:
    - name: DATABASE_HOST
      value: {{ include "temporal.database.default.host" .context | quote }}
    - name: DATABASE_PORT_NUMBER
      value: {{ include "temporal.database.default.port" .context | quote }}
    - name: DATABASE_NAME
      value: {{ include "temporal.database.default.name" .context | quote }}
    - name: DATABASE_USER
      value: {{ include "temporal.database.default.username" .context | quote }}
    {{- if .context.Values.usePasswordFiles }}
    - name: DATABASE_PASSWORD_FILE
      value: "/opt/bitnami/postgresql/db-credentials/default-store-password"
    {{- else }}
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "temporal.database.default.secretName" .context }}
          key: {{ include "temporal.database.default.secretPasswordKey" .context }}
    {{- end }}
    - name: DATABASE_READY_QUERY
      value: {{ ternary "SELECT 1 FROM information_schema.tables WHERE table_name='schema_version'" "SELECT 1" .initialized }}
    {{- if include "common.fips.enabled" .context }}
    - name: OPENSSL_FIPS
      value: {{ include "common.fips.config" (dict "tech" "openssl" "fips" .context.Values.defaultInitContainers.waitForDB.fips "global" .context.Values.global) | quote }}
    {{- end }}
  volumeMounts:
    - name: empty-dir
      mountPath: /tmp
      subPath: tmp-dir
    {{- if .context.Values.usePasswordFiles }}
    - name: db-credentials
      mountPath: /opt/bitnami/postgresql/db-credentials
    {{- end }}
{{- end }}

{{/*
Returns an init-container that renders config template
*/}}
{{- define "temporal.defaultInitContainers.renderConfig" -}}
- name: render-config
  image: {{ template "temporal.image" .context }}
  imagePullPolicy: {{ .context.Values.image.pullPolicy }}
  {{- if .context.Values.defaultInitContainers.renderConfig.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .context.Values.defaultInitContainers.renderConfig.containerSecurityContext "context" .context) | nindent 4 }}
  {{- end }}
  {{- if .context.Values.defaultInitContainers.renderConfig.resources }}
  resources: {{- toYaml .context.Values.defaultInitContainers.renderConfig.resources | nindent 4 }}
  {{- else if ne .context.Values.defaultInitContainers.renderConfig.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .context.Values.defaultInitContainers.renderConfig.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
  - /bin/bash
  args:
    - -ec
    - |
      {{- if .context.Values.usePasswordFiles }}
      export TEMPORAL_STORE_PASSWORD="$(< $TEMPORAL_STORE_PASSWORD_FILE)"
      export TEMPORAL_VISIBILITY_STORE_PASSWORD="$(< $TEMPORAL_VISIBILITY_STORE_PASSWORD_FILE)"
      {{- end }}
      dockerize -template /template/config_template.yaml:/config/docker.yaml
  env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: TEMPORAL_SERVICES
      value: {{ .component | quote }}
    {{- if .context.Values.usePasswordFiles }}
    - name: TEMPORAL_STORE_PASSWORD_FILE
      value: "/opt/bitnami/temporal/db-credentials/default-store-password"
    - name: TEMPORAL_VISIBILITY_STORE_PASSWORD_FILE
      value: "/opt/bitnami/temporal/db-credentials/visibility-store-password"
    {{- else }}
    - name: TEMPORAL_STORE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "temporal.database.default.secretName" .context }}
          key: {{ include "temporal.database.default.secretPasswordKey" .context }}
    - name: TEMPORAL_VISIBILITY_STORE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "temporal.database.visibility.secretName" .context }}
          key: {{ include "temporal.database.visibility.secretPasswordKey" .context }}
    {{- end }}
    {{- if include "common.fips.enabled" .context }}
    - name: OPENSSL_FIPS
      value: {{ include "common.fips.config" (dict "tech" "openssl" "fips" .context.Values.defaultInitContainers.renderConfig.fips "global" .context.Values.global) | quote }}
    - name: GODEBUG
      value: {{ include "common.fips.config" (dict "tech" "golang" "fips" .context.Values.defaultInitContainers.renderConfig.fips "global" .context.Values.global) | quote }}
    {{- end }}
  volumeMounts:
    - name: configuration
      mountPath: /template/config_template.yaml
      subPath: config_template.yaml
    - name: empty-dir
      mountPath: /config
      subPath: app-conf-dir
    {{- if .context.Values.usePasswordFiles }}
    - name: db-credentials
      mountPath: /opt/bitnami/temporal/db-credentials
    {{- end }}
{{- end }}

{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Returns an init-container that changes the owner and group of the persistent volume(s) mountpoint(s) to 'runAsUser:fsGroup' on each node
*/}}
{{- define "postgresql-ha.defaultInitContainers.volumePermissions" -}}
{{- $componentValues := index .context.Values .component -}}
- name: volume-permissions
  image: {{ include "postgresql-ha.volumePermissions.image" .context }}
  imagePullPolicy: {{ .context.Values.defaultInitContainers.volumePermissions.image.pullPolicy | quote }}
  {{- if .context.Values.defaultInitContainers.volumePermissions.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .context.Values.defaultInitContainers.volumePermissions.containerSecurityContext "context" .context) | nindent 4 }}
  {{- end }}
  {{- if .context.Values.defaultInitContainers.volumePermissions.resources }}
  resources: {{- toYaml .context.Values.defaultInitContainers.volumePermissions.resources | nindent 4 }}
  {{- else if ne .context.Values.defaultInitContainers.volumePermissions.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .context.Values.defaultInitContainers.volumePermissions.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
      echo "Adapting volumes permissions"
    {{- if and .context.Values.defaultInitContainers.volumePermissions.enabled (or (or (not (empty $componentValues.extendedConf)) (not (empty $componentValues.extendedConfCM))) .context.Values.persistence.enabled) }}
      mkdir -p {{ .context.Values.persistence.mountPath }}/conf {{ .context.Values.persistence.mountPath }}/data {{ .context.Values.persistence.mountPath }}/lock
      chmod 700 {{ .context.Values.persistence.mountPath }}/conf {{ .context.Values.persistence.mountPath }}/data {{ .context.Values.persistence.mountPath }}/lock
      {{- if eq ( toString ( .context.Values.defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser )) "auto" }}
      chown $(id -u):$(id -G | cut -d " " -f2) {{ .context.Values.persistence.mountPath }}
      find {{ .context.Values.persistence.mountPath }} -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R $(id -u):$(id -G | cut -d " " -f2)
      {{- else }}
      chown {{ $componentValues.containerSecurityContext.runAsUser }}:{{ $componentValues.podSecurityContext.fsGroup }} {{ .context.Values.persistence.mountPath }}
      find {{ .context.Values.persistence.mountPath }} -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R {{ $componentValues.containerSecurityContext.runAsUser }}:{{ $componentValues.podSecurityContext.fsGroup }}
      {{- end }}
    {{- end }}
    {{- if .context.Values.postgresql.tls.enabled }}
      cp /tmp/certs/* /opt/bitnami/postgresql/certs
      {{- if eq ( toString ( .context.Values.defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser )) "auto" }}
      find /opt/bitnami/postgresql/certs -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R $(id -u):$(id -G | cut -d " " -f2)
      {{- else }}
      find /opt/bitnami/postgresql/certs -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R {{ $componentValues.containerSecurityContext.runAsUser }}:{{ $componentValues.podSecurityContext.fsGroup }}
      {{- end }}
      chmod 600 {{ include "postgresql-ha.postgresql.tlsCertKey" .context }}
    {{- end }}
      echo "Done"
  volumeMounts:
    {{- if and .context.Values.defaultInitContainers.volumePermissions.enabled (or (or (not (empty $componentValues.extendedConf)) (not (empty $componentValues.extendedConfCM))) .context.Values.persistence.enabled) }}
    - name: data
      mountPath: {{ .context.Values.persistence.mountPath }}
    {{- end }}
    {{- if .context.Values.postgresql.tls.enabled }}
    - name: raw-certificates
      mountPath: /tmp/certs
    - name: postgresql-certificates
      mountPath: /opt/bitnami/postgresql/certs
    {{- end }}
{{- end -}}

{{/*
Returns an init-container that sets up the PostgreSQL+repmgr instance
*/}}
{{- define "postgresql-ha.defaultInitContainers.setup" -}}
{{- $componentValues := index .context.Values .component -}}
- name: setup
  image: {{ include "postgresql-ha.postgresql.image" .context }}
  imagePullPolicy: {{ .context.Values.postgresql.image.pullPolicy }}
  {{- if .context.Values.defaultInitContainers.setup.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .context.Values.defaultInitContainers.setup.containerSecurityContext "context" .context) | nindent 4 }}
  {{- end }}
  {{- if .context.Values.defaultInitContainers.setup.resources }}
  resources: {{- toYaml .context.Values.defaultInitContainers.setup.resources | nindent 4 }}
  {{- else if ne .context.Values.defaultInitContainers.setup.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .context.Values.defaultInitContainers.setup.resourcesPreset) | nindent 4 }}
  {{- end }}
  args: ["/opt/bitnami/scripts/postgresql-repmgr/setup.sh"]
  env:
    {{- include "postgresql-ha.postgresql.commonEnvVars" (dict "component" .component "context" .context) | nindent 4 }}
    {{- if not .context.Values.postgresql.usePasswordFiles }}
    {{- include "postgresql-ha.postgresql.passwordEnvVars" .context | nindent 4 }}
    {{- end }}
    - name: POSTGRESQL_SHARED_PRELOAD_LIBRARIES
      value: {{ .context.Values.postgresql.sharedPreloadLibraries | quote }}
    - name: POSTGRESQL_ENABLE_TLS
      value: {{ ternary "yes" "no" .context.Values.postgresql.tls.enabled | quote }}
    {{- if .context.Values.postgresql.tls.enabled }}
    - name: POSTGRESQL_TLS_PREFER_SERVER_CIPHERS
      value: {{ ternary "yes" "no" .context.Values.postgresql.tls.preferServerCiphers | quote }}
    - name: POSTGRESQL_TLS_CERT_FILE
      value: {{ template "postgresql-ha.postgresql.tlsCert" .context }}
    - name: POSTGRESQL_TLS_KEY_FILE
      value: {{ template "postgresql-ha.postgresql.tlsCertKey" .context }}
    {{- end }}
    - name: POSTGRESQL_LOG_HOSTNAME
      value: {{ $componentValues.audit.logHostname | quote }}
    - name: POSTGRESQL_LOG_CONNECTIONS
      value: {{ $componentValues.audit.logConnections | quote }}
    - name: POSTGRESQL_LOG_DISCONNECTIONS
      value: {{ $componentValues.audit.logDisconnections | quote }}
    {{- if $componentValues.audit.logLinePrefix }}
    - name: POSTGRESQL_LOG_LINE_PREFIX
      value: {{ $componentValues.audit.logLinePrefix | quote }}
    {{- end }}
    {{- if $componentValues.audit.logTimezone }}
    - name: POSTGRESQL_LOG_TIMEZONE
      value: {{ $componentValues.audit.logTimezone | quote }}
    {{- end }}
    {{- if $componentValues.audit.pgAuditLog }}
    - name: POSTGRESQL_PGAUDIT_LOG
      value: {{ $componentValues.audit.pgAuditLog | quote }}
    {{- end }}
    - name: POSTGRESQL_PGAUDIT_LOG_CATALOG
      value: {{ $componentValues.audit.pgAuditLogCatalog | quote }}
    - name: POSTGRESQL_CLIENT_MIN_MESSAGES
      value: {{ $componentValues.audit.clientMinMessages | quote }}
    {{- if $componentValues.maxConnections }}
    - name: POSTGRESQL_MAX_CONNECTIONS
      value: {{ $componentValues.maxConnections | quote }}
    {{- end }}
    {{- if $componentValues.postgresConnectionLimit }}
    - name: POSTGRESQL_POSTGRES_CONNECTION_LIMIT
      value: {{ $componentValues.postgresConnectionLimit | quote }}
    {{- end }}
    {{- if $componentValues.dbUserConnectionLimit }}
    - name: POSTGRESQL_USERNAME_CONNECTION_LIMIT
      value: {{ $componentValues.dbUserConnectionLimit | quote }}
    {{- end }}
    {{- if $componentValues.tcpKeepalivesInterval }}
    - name: POSTGRESQL_TCP_KEEPALIVES_INTERVAL
      value: {{ $componentValues.tcpKeepalivesInterval | quote }}
    {{- end }}
    {{- if $componentValues.tcpKeepalivesIdle }}
    - name: POSTGRESQL_TCP_KEEPALIVES_IDLE
      value: {{ $componentValues.tcpKeepalivesIdle | quote }}
    {{- end }}
    {{- if $componentValues.tcpKeepalivesCount }}
    - name: POSTGRESQL_TCP_KEEPALIVES_COUNT
      value: {{ $componentValues.tcpKeepalivesCount | quote }}
    {{- end }}
    {{- if $componentValues.statementTimeout }}
    - name: POSTGRESQL_STATEMENT_TIMEOUT
      value: {{ $componentValues.statementTimeout | quote }}
    {{- end }}
    {{- if $componentValues.pghbaRemoveFilters }}
    - name: POSTGRESQL_PGHBA_REMOVE_FILTERS
      value: {{ $componentValues.pghbaRemoveFilters | quote }}
    {{- end }}
    - name: REPMGR_UPGRADE_EXTENSION
      value: {{ ternary "yes" "no" $componentValues.upgradeRepmgrExtension | quote }}
    - name: REPMGR_PGHBA_TRUST_ALL
      value: {{ ternary "yes" "no" $componentValues.pgHbaTrustAll | quote }}
    - name: REPMGR_MOUNTED_CONF_DIR
      value: "/bitnami/repmgr/conf"
    - name: REPMGR_NODE_NAME
      value: "$(MY_POD_NAME)"
    - name: REPMGR_LOG_LEVEL
      value: {{ $componentValues.repmgrLogLevel | quote }}
    - name: REPMGR_CONNECT_TIMEOUT
      value: {{ $componentValues.repmgrConnectTimeout | quote }}
    - name: REPMGR_RECONNECT_ATTEMPTS
      value: {{ $componentValues.repmgrReconnectAttempts | quote }}
    - name: REPMGR_RECONNECT_INTERVAL
      value: {{ $componentValues.repmgrReconnectInterval | quote }}
    {{- if .context.Values.postgresql.repmgrUsePassfile }}
    - name: REPMGR_USE_PASSFILE
      value: {{ ternary "true" "false" .context.Values.postgresql.repmgrUsePassfile | quote }}
    - name: REPMGR_PASSFILE_PATH
      value: {{ default "/opt/bitnami/repmgr/conf/.pgpass" .context.Values.postgresql.repmgrPassfilePath }}
    {{- end }}
  {{- if eq .component "postgresql" }}
    - name: REPMGR_NODE_TYPE
      value: "data"
    - name: REPMGR_FENCE_OLD_PRIMARY
      value: {{ ternary "yes" "no" $componentValues.repmgrFenceOldPrimary | quote }}
    {{- if $componentValues.usePgRewind }}
    - name: REPMGR_USE_PGREWIND
      value: {{ $componentValues.usePgRewind | quote }}
    {{- end }}
    {{- if $componentValues.repmgrChildNodesCheckInterval }}
    - name: REPMGR_CHILD_NODES_CHECK_INTERVAL
      value: {{ $componentValues.repmgrChildNodesCheckInterval | quote }}
    {{- end }}
    {{- if $componentValues.repmgrChildNodesConnectedMinCount }}
    - name: REPMGR_CHILD_NODES_CONNECTED_MIN_COUNT
      value: {{ $componentValues.repmgrChildNodesConnectedMinCount | quote }}
    {{- end }}
    {{- if $componentValues.repmgrChildNodesDisconnectTimeout }}
    - name: REPMGR_CHILD_NODES_DISCONNECT_TIMEOUT
      value: {{ $componentValues.repmgrChildNodesDisconnectTimeout | quote }}
    {{- end }}
    - name: REPMGR_DEGRADED_MONITORING_TIMEOUT
      value: {{ $componentValues.preStopDelayAfterPgStopSeconds | quote }}
  {{- else }}
    - name: REPMGR_NODE_TYPE
      value: "witness"
    - name: REPMGR_NODE_ID_START_SEED
      value: "2000"
  {{- end }}
    {{- if $componentValues.extraEnvVars }}
    {{- include "common.tplvalues.render" (dict "value" $componentValues.extraEnvVars "context" .) | nindent 4 }}
    {{- end }}
  envFrom:
    - configMapRef:
        name: {{ printf "%s-common-env" (include "postgresql-ha.postgresql" .context) }}
  volumeMounts:
    - name: empty-dir
      mountPath: /tmp
      subPath: tmp-dir
    - name: empty-dir
      mountPath: /opt/bitnami/postgresql/conf
      subPath: app-conf-dir
    - name: empty-dir
      mountPath: /opt/bitnami/postgresql/tmp
      subPath: app-tmp-dir
    - name: empty-dir
      mountPath: /opt/bitnami/repmgr/conf
      subPath: repmgr-conf-dir
    - name: empty-dir
      mountPath: /opt/bitnami/repmgr/tmp
      subPath: repmgr-tmp-dir
    - name: empty-dir
      mountPath: /opt/bitnami/repmgr/logs
      subPath: repmgr-logs-dir
    {{- if or $componentValues.repmgrConfiguration $componentValues.configuration $componentValues.pgHbaConfiguration $componentValues.configurationCM }}
    - name: postgresql-config
      mountPath: /bitnami/repmgr/conf
    {{- end }}
    {{- if or $componentValues.extendedConf $componentValues.extendedConfCM }}
    - name: postgresql-extended-config
      mountPath: /bitnami/postgresql/conf/conf.d
    {{- end }}
    {{- if or $componentValues.initdbScriptsCM $componentValues.initdbScripts }}
    - name: custom-init-scripts
      mountPath: /docker-entrypoint-initdb.d
    {{- end }}
    {{- if $componentValues.initdbScriptsSecret }}
    - name: custom-init-scripts-secret
      mountPath: /docker-entrypoint-initdb.d/secret
    {{- end }}
    {{- if .context.Values.postgresql.usePasswordFiles }}
    {{- if not (eq (include "postgresql-ha.postgresqlUsername" .context) "postgres") }}
    - name: postgresql-creds
      mountPath: /opt/bitnami/postgresql/secrets/postgres-password
      subPath: postgres-password
    {{- end }}
    - name: postgresql-creds
      subPath: password
      mountPath: /opt/bitnami/postgresql/secrets/password
    - name: postgresql-creds
      subPath: repmgr-password
      mountPath: /opt/bitnami/postgresql/secrets/repmgr-password
    - name: pgpool-creds
      subPath: sr-check-password
      mountPath: /opt/bitnami/postgresql/secrets/sr-check-password
    {{- end }}
    {{- if .context.Values.postgresql.tls.enabled }}
    - name: postgresql-certificates
      mountPath: /opt/bitnami/postgresql/certs
    {{- end }}
    - name: data
      mountPath: {{ .context.Values.persistence.mountPath }}
{{- end -}}

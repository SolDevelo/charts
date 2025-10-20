{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/*
Returns an init-container that changes the owner and group of the persistent volume mountpoint
*/}}
{{- define "mariadb.defaultInitContainers.volumePermissions" -}}
{{- $componentValues := index .context.Values .component -}}
- name: volume-permissions
  image: {{ include "mariadb.volumePermissions.image" .context }}
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
      mkdir -p {{ $componentValues.persistence.mountPath }}
      {{- if eq ( toString ( .context.Values.defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser )) "auto" }}
      find {{ $componentValues.persistence.mountPath }} -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R $(id -u):$(id -G | cut -d " " -f2)
      {{- else }}
      find {{ $componentValues.persistence.mountPath }} -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R {{ $componentValues.containerSecurityContext.runAsUser }}:{{ $componentValues.podSecurityContext.fsGroup }}
      {{- end }}
  {{- if include "common.fips.enabled" .context }}
  env:
    - name: OPENSSL_FIPS
      value: {{ include "common.fips.config" (dict "tech" "openssl" "fips" .context.Values.defaultInitContainers.volumePermissions.fips "global" .context.Values.global) | quote }}
  {{- end }}
  volumeMounts:
    - name: data
      mountPath: {{ $componentValues.persistence.mountPath }}
      {{- if $componentValues.persistence.subPath }}
      subPath: {{ $componentValues.persistence.subPath }}
      {{- end }}
{{- end -}}

{{/*
Returns an init-container that sets up the MariaDB instance
*/}}
{{- define "mariadb.defaultInitContainers.setup" -}}
{{- $componentValues := index .context.Values .component -}}
- name: setup
  image: {{ include "mariadb.setup.image" .context }}
  imagePullPolicy: {{ .context.Values.defaultInitContainers.setup.image.pullPolicy }}
  {{- if .context.Values.defaultInitContainers.setup.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .context.Values.defaultInitContainers.setup.containerSecurityContext "context" .context) | nindent 4 }}
  {{- end }}
  {{- if .context.Values.defaultInitContainers.setup.resources }}
  resources: {{- toYaml .context.Values.defaultInitContainers.setup.resources | nindent 4 }}
  {{- else if ne .context.Values.defaultInitContainers.setup.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .context.Values.defaultInitContainers.setup.resourcesPreset) | nindent 4 }}
  {{- end }}
  args: ["/opt/bitnami/scripts/mariadb/setup.sh"]
  env:
    - name: BITNAMI_DEBUG
      value: {{ ternary "true" "false" .context.Values.defaultInitContainers.setup.image.debug | quote }}
    {{- if .context.Values.auth.usePasswordFiles }}
    - name: {{ ternary "MARIADB_ROOT_PASSWORD_FILE" "MARIADB_MASTER_ROOT_PASSWORD_FILE" (eq .component "primary") }}
      value: {{ default "/opt/bitnami/mariadb/secrets/mariadb-root-password" .context.Values.auth.customPasswordFiles.root }}
    {{- else }}
    - name: {{ ternary "MARIADB_ROOT_PASSWORD" "MARIADB_MASTER_ROOT_PASSWORD" (eq .component "primary") }}
      valueFrom:
        secretKeyRef:
          name: {{ template "mariadb.secretName" .context }}
          key: mariadb-root-password
    {{- end }}
  {{- if eq .component "primary" }}
    {{- if not (empty .context.Values.auth.username) }}
    - name: MARIADB_USER
      value: {{ .context.Values.auth.username | quote }}
    {{- if .context.Values.auth.usePasswordFiles }}
    - name: MARIADB_PASSWORD_FILE
      value: {{ default "/opt/bitnami/mariadb/secrets/mariadb-password" .context.Values.auth.customPasswordFiles.user }}
    {{- else }}
    - name: MARIADB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ template "mariadb.secretName" .context }}
          key: mariadb-password
    {{- end }}
    {{- end }}
    - name: MARIADB_DATABASE
      value: {{ .context.Values.auth.database | quote }}
  {{- else }}
    - name: MARIADB_MASTER_HOST
      value: {{ include "mariadb.primary.fullname" .context }}
    - name: MARIADB_MASTER_PORT_NUMBER
      value: {{ .context.Values.primary.service.ports.mysql | quote }}
    - name: MARIADB_MASTER_ROOT_USER
      value: "root"
  {{- end }}
    {{- if eq .context.Values.architecture "replication" }}
    - name: MARIADB_REPLICATION_MODE
      value: {{ ternary "master" "slave" (eq .component "primary") | quote }}
    - name: MARIADB_REPLICATION_USER
      value: {{ .context.Values.auth.replicationUser | quote }}
    {{- if .context.Values.auth.usePasswordFiles }}
    - name: MARIADB_REPLICATION_PASSWORD_FILE
      value: {{ default "/opt/bitnami/mariadb/secrets/mariadb-replication-password" .context.Values.auth.customPasswordFiles.replicator }}
    {{- else }}
    - name: MARIADB_REPLICATION_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ template "mariadb.secretName" .context }}
          key: mariadb-replication-password
    {{- end }}
    {{- end }}
    - name: MARIADB_ENABLE_SSL
      value: {{ ternary "yes" "no" .context.Values.tls.enabled | quote }}
    {{- if .context.Values.tls.enabled }}
    - name: MYSQL_CLIENT_CA_FILE
      value: "/opt/bitnami/mariadb/certs/ca.crt"
    {{- end }}
    {{- if .context.Values.defaultInitContainers.setup.startupWaitOptions }}
    - name: MARIADB_STARTUP_WAIT_RETRIES
      value: {{ .context.Values.defaultInitContainers.setup.startupWaitOptions.retries | default 300 | quote }}
    - name: MARIADB_STARTUP_WAIT_SLEEP_TIME
      value: {{ .context.Values.defaultInitContainers.setup.startupWaitOptions.sleepTime | default 2 | quote }}
    {{- end }}
    {{- if include "common.fips.enabled" .context }}
    - name: OPENSSL_FIPS
      value: {{ include "common.fips.config" (dict "tech" "openssl" "fips" .context.Values.defaultInitContainers.setup.fips "global" .context.Values.global) | quote }}
    {{- end }}
  volumeMounts:
    - name: data
      mountPath: {{ $componentValues.persistence.mountPath }}
      {{- if $componentValues.persistence.subPath }}
      subPath: {{ $componentValues.persistence.subPath }}
      {{- end }}
    {{- if and (eq .component "primary") (or .context.Values.initdbScriptsConfigMap .context.Values.initdbScripts) }}
    - name: custom-init-scripts
      mountPath: /docker-entrypoint-initdb.d
    {{- end }}
    - name: config
      mountPath: /opt/bitnami/mariadb/conf/my.cnf
      subPath: my.cnf
    {{- if and .context.Values.auth.usePasswordFiles (not .context.Values.auth.customPasswordFiles) }}
    - name: mariadb-credentials
      mountPath: /opt/bitnami/mariadb/secrets/
    {{- end }}
    {{- if .context.Values.tls.enabled }}
    - name: tls-certs
      mountPath: /opt/bitnami/mariadb/certs
    {{- end }}
    - name: empty-dir
      mountPath: /opt/bitnami/mariadb/conf
      subPath: app-conf-dir
    - name: empty-dir
      mountPath: /opt/bitnami/mariadb/tmp
      subPath: app-tmp-dir
    - name: empty-dir
      mountPath: /opt/bitnami/mariadb/logs
      subPath: app-logs-dir
    - name: empty-dir
      mountPath: /tmp
      subPath: tmp-dir
{{- end -}}

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

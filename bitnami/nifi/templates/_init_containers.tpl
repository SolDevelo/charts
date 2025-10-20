{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Returns an init-container that copyies the NiFi configuration files for main containers to use them
*/}}
{{- define "nifi.defaultInitContainers.copyConfig" -}}
- name: copy-config
  image: {{ include "nifi.image" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if .Values.defaultInitContainers.copyConfig.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.defaultInitContainers.copyConfig.containerSecurityContext "context" .) | nindent 4 }}
  {{- end }}
  {{- if .Values.defaultInitContainers.copyConfig.resources }}
  resources: {{- toYaml .Values.defaultInitContainers.copyConfig.resources | nindent 4 }}
  {{- else if ne .Values.defaultInitContainers.copyConfig.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .Values.defaultInitContainers.copyConfig.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
        echo "Copying NiFi configuration"
        cp -rL /opt/bitnami/nifi/conf/* /bitnami/nifi/pre-render-conf/
        echo "NiFi configuration copied"
  env:
    {{- if .Values.extraEnvVars }}
    {{- include "common.tplvalues.render" (dict "value" .Values.extraEnvVars "context" $) | nindent 4 }}
    {{- end }}
  volumeMounts:
    - name: empty-dir
      mountPath: /bitnami/nifi/pre-render-conf
      subPath: app-pre-render-conf-dir
{{- end -}}

{{/*
Returns an init-container that prepares the NiFi configuration files for main containers to use them
*/}}
{{- define "nifi.defaultInitContainers.renderConfig" -}}
- name: render-config
  image: {{ include "nifi.init-containers.default-image" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if .Values.defaultInitContainers.renderConfig.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.defaultInitContainers.renderConfig.containerSecurityContext "context" .) | nindent 4 }}
  {{- end }}
  {{- if .Values.defaultInitContainers.renderConfig.resources }}
  resources: {{- toYaml .Values.defaultInitContainers.renderConfig.resources | nindent 4 }}
  {{- else if ne .Values.defaultInitContainers.renderConfig.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .Values.defaultInitContainers.renderConfig.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
        {{- if .Values.usePasswordFiles }}
        export NIFI_SENSITIVE_PROPS_KEY="$(< $NIFI_SENSITIVE_PROPS_KEY_FILE)"
        {{- end }}

        replace_in_file() {
            local filename="${1:?filename is required}"
            local match_regex="${2:?match regex is required}"
            local substitute_regex="${3:?substitute regex is required}"

            local result

            # We should avoid using 'sed in-place' substitutions
            # 1) They are not compatible with files mounted from ConfigMap(s)
            # 2) We found incompatibility issues with Debian10 and "in-place" substitutions
            local -r del=$'\001' # Use a non-printable character as a 'sed' delimiter to avoid issues
            result="$(sed -E "s${del}${match_regex}${del}${substitute_regex}${del}g" "$filename")"
            echo "$result" > "$filename"
        }

        echo "Preparing NiFi configuration"
        # Overwrite the default files with the mounted ones
        cp -L /bitnami/nifi/mounted-conf/* /bitnami/nifi/pre-render-conf/
        for conffile in /bitnami/nifi/pre-render-conf/*; do
            filename="$(basename $conffile)"
            render-template $conffile > /bitnami/nifi/rendered-conf/$filename
        done

        # Modify the Kubernetes provider XML to include the release name as ConfigMap prefix
        replace_in_file "/bitnami/nifi/rendered-conf/state-management.xml" 'ConfigMap Name Prefix">' 'ConfigMap Name Prefix">{{ include "common.names.fullname" .}}'
        # Modify the Local provider XML to use {{ .Values.persistence.mountPath }}/state as the local state directory
        echo "NiFi configuration prepared"
        replace_in_file "/bitnami/nifi/rendered-conf/state-management.xml" '"Directory">./state/local' '"Directory">{{ .Values.persistence.mountPath }}/state'
  env:
    {{- if .Values.usePasswordFiles }}
    - name: NIFI_SENSITIVE_PROPS_KEY_FILE
      value: /bitnami/nifi/secrets/{{ include "nifi.sensitive-props.secretKey" . }}
    {{- else }}
    - name: NIFI_SENSITIVE_PROPS_KEY
      valueFrom:
        secretKeyRef:
          name: {{ include "nifi.sensitive-props.secretName" . }}
          key: {{ include "nifi.sensitive-props.secretKey" . }}
    {{- end }}
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    {{- if .Values.extraEnvVars }}
    {{- include "common.tplvalues.render" (dict "value" .Values.extraEnvVars "context" $) | nindent 4 }}
    {{- end }}
  volumeMounts:
    - name: empty-dir
      mountPath: /bitnami/nifi/rendered-conf
      subPath: app-rendered-conf-dir
    - name: empty-dir
      mountPath: /bitnami/nifi/pre-render-conf
      subPath: app-pre-render-conf-dir
    - name: configuration
      mountPath: /bitnami/nifi/mounted-conf
    {{- if .Values.usePasswordFiles }}
    - name: nifi-secrets
      mountPath: /bitnami/nifi/secrets
    {{- end }}
{{- end -}}

{{/*
Returns an init-container that prepares CA for accessing kube-apiserver and other NiFi components
*/}}
{{- define "nifi.defaultInitContainers.importCA" -}}
- name: import-ca
  image: {{ include "nifi.image" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if .Values.defaultInitContainers.importCA.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.defaultInitContainers.importCA.containerSecurityContext "context" .) | nindent 4 }}
  {{- end }}
  {{- if .Values.defaultInitContainers.importCA.resources }}
  resources: {{- toYaml .Values.defaultInitContainers.importCA.resources | nindent 4 }}
  {{- else if ne .Values.defaultInitContainers.importCA.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .Values.defaultInitContainers.importCA.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
        echo "Importing CA certificates"
        # Copy original cacerts
        cp /opt/bitnami/java/lib/security/cacerts /bitnami/nifi/cacerts/
        echo "Importing Kubernetes cluster CA"
        keytool -importcert -file /bitnami/nifi/kube-root-ca/ca.crt -keystore /bitnami/nifi/cacerts/cacerts -alias "kubernetes" -noprompt
        {{- if .Values.tls.enabled }}
        if [[ -f /bitnami/nifi/certs/{{ .Values.tls.certCAFilename }} ]]; then
            echo "Importing TLS certificate CA"
            keytool -importcert -file /bitnami/nifi/certs/{{ .Values.tls.certCAFilename }} -keystore /bitnami/nifi/cacerts/cacerts -alias "imported_tls" -noprompt
        fi
        {{- end }}
        echo "CA certificates imported"
  env:
    {{- if include "common.fips.enabled" . }}
    - name: OPENSSL_FIPS
      value: {{ include "common.fips.config" (dict "tech" "openssl" "fips" .Values.defaultInitContainers.importCA.fips "global" .Values.global) | quote }}
    - name: JAVA_TOOL_OPTIONS
      value: {{ include "common.fips.config" (dict "tech" "java" "fips" .Values.defaultInitContainers.importCA.fips "global" .Values.global) | quote }}
    {{- end }}
    {{- if .Values.extraEnvVars }}
    {{- include "common.tplvalues.render" (dict "value" .Values.extraEnvVars "context" $) | nindent 4 }}
    {{- end }}
  volumeMounts:
    - name: empty-dir
      mountPath: /bitnami/nifi/cacerts
      subPath: app-cacerts-dir
    - name: kube-root-ca
      mountPath: /bitnami/nifi/kube-root-ca
    {{- if .Values.tls.enabled }}
    - name: tls-certs
      mountPath: /bitnami/nifi/certs
    {{- end }}
{{- end -}}

{{/*
Returns an init-container that prepares the NiFi configuration files for main containers to use them
*/}}
{{- define "nifi.defaultInitContainers.setAuth" -}}
- name: set-auth
  image: {{ include "nifi.image" . }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if .Values.defaultInitContainers.setAuth.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.defaultInitContainers.renderConfig.containerSecurityContext "context" .) | nindent 4 }}
  {{- end }}
  {{- if .Values.defaultInitContainers.setAuth.resources }}
  resources: {{- toYaml .Values.defaultInitContainers.setAuth.resources | nindent 4 }}
  {{- else if ne .Values.defaultInitContainers.setAuth.resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .Values.defaultInitContainers.setAuth.resourcesPreset) | nindent 4 }}
  {{- end }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
        {{- if .Values.usePasswordFiles }}
        export NIFI_USERNAME="$(< $NIFI_USERNAME_FILE)"
        export NIFI_PASSWORD="$(< $NIFI_PASSWORD_FILE)"
        {{- end }}
        echo "Setting NiFi authentication"
        nifi.sh set-single-user-credentials $NIFI_USERNAME $NIFI_PASSWORD
        echo "NiFi authentication set"
  env:
    {{- if .Values.usePasswordFiles }}
    - name: NIFI_USERNAME_FILE
      value: /bitnami/nifi/secrets/{{ include "nifi.auth.secretUsernameKey" . }}
    - name: NIFI_PASSWORD_FILE
      value: /bitnami/nifi/secrets/{{ include "nifi.auth.secretPasswordKey" . }}
    {{- else }}
    - name: NIFI_USERNAME
      valueFrom:
        secretKeyRef:
          name: {{ include "nifi.auth.secretName" . }}
          key: {{ include "nifi.auth.secretUsernameKey" . }}
    - name: NIFI_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "nifi.auth.secretName" . }}
          key: {{ include "nifi.auth.secretPasswordKey" . }}
    {{- end }}
    {{- if include "common.fips.enabled" . }}
    - name: OPENSSL_FIPS
      value: {{ include "common.fips.config" (dict "tech" "openssl" "fips" .Values.defaultInitContainers.setAuth.fips "global" .Values.global) | quote }}
    - name: JAVA_TOOL_OPTIONS
      value: {{ include "common.fips.config" (dict "tech" "java" "fips" .Values.defaultInitContainers.setAuth.fips "global" .Values.global) | quote }}
    {{- end }}
    {{- if .Values.extraEnvVars }}
    {{- include "common.tplvalues.render" (dict "value" .Values.extraEnvVars "context" $) | nindent 4 }}
    {{- end }}
  volumeMounts:
    - name: empty-dir
      mountPath: /opt/bitnami/nifi/conf
      subPath: app-rendered-conf-dir
    {{- if .Values.usePasswordFiles }}
    - name: nifi-secrets
      mountPath: /bitnami/nifi/secrets
    {{- end }}
{{- end -}}

{{/*
Returns an init-container that fixes the volume permissions
*/}}
{{- define "nifi.init-containers.volume-permissions" -}}
- name: volume-permissions
  image: {{ include "nifi.init-containers.default-image" . }}
  imagePullPolicy: {{ .Values.defaultInitContainers.defaultImage.pullPolicy | quote }}
  command:
    - /bin/bash
    - -ec
    - |
      {{- if eq ( toString ( .Values.defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser )) "auto" }}
      find {{ .Values.persistence.mountPath }} -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R $(id -u):$(id -G | cut -d " " -f2)
      {{- else }}
      find {{ .Values.persistence.mountPath }} -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" |  xargs -r chown -R {{ .Values.containerSecurityContext.runAsUser }}:{{ .Values.podSecurityContext.fsGroup }}
      {{- end }}
  {{- if .Values.defaultInitContainers.volumePermissions.containerSecurityContext.enabled }}
  securityContext: {{- include "common.compatibility.renderSecurityContext" (dict "secContext" .Values.defaultInitContainers.volumePermissions.containerSecurityContext "context" $) | nindent 4 }}
  {{- end }}
  {{- if .Values.defaultInitContainers.volumePermissions.resources }}
  resources: {{- toYaml .Values.defaultInitContainers.volumePermissions.resources | nindent 4 }}
  {{- else if ne .resourcesPreset "none" }}
  resources: {{- include "common.resources.preset" (dict "type" .Values.defaultInitContainers.volumePermissions.resourcesPreset) | nindent 4 }}
  {{- end }}
  volumeMounts:
    - name: data
      mountPath: {{ .Values.persistence.mountPath }}
      {{- if .Values.persistence.subPath }}
      subPath: {{ .Values.persistence.subPath }}
      {{- end }}
{{- end -}}

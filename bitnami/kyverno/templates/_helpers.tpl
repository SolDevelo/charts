{{/*
Copyright Broadcom, Inc. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/*
Return the proper Kyverno Admission Controller image name
*/}}
{{- define "kyverno.admission-controller.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.admissionController.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Kyverno Background Controller image name
*/}}
{{- define "kyverno.background-controller.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.backgroundController.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Kyverno Cleanup Controller image name
*/}}
{{- define "kyverno.cleanup-controller.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.cleanupController.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Kyverno Reports Controller image name
*/}}
{{- define "kyverno.reports-controller.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.reportsController.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Kyverno Admission Controller fullname
*/}}
{{- define "kyverno.admission-controller.fullname" -}}
{{- printf "%s-%s" (include "common.names.fullname" .) "admission-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Admission Controller fullname (namespace)
*/}}
{{- define "kyverno.admission-controller.fullname.namespace" -}}
{{- printf "%s-%s" (include "common.names.fullname.namespace" .) "admission-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Background Controller fullname
*/}}
{{- define "kyverno.background-controller.fullname" -}}
{{- printf "%s-%s" (include "common.names.fullname" .) "background-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Background Controller fullname (namespace)
*/}}
{{- define "kyverno.background-controller.fullname.namespace" -}}
{{- printf "%s-%s" (include "common.names.fullname.namespace" .) "background-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Cleanup Controller fullname
*/}}
{{- define "kyverno.cleanup-controller.fullname" -}}
{{- printf "%s-%s" (include "common.names.fullname" .) "cleanup-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Cleanup Controller fullname (namespace)
*/}}
{{- define "kyverno.cleanup-controller.fullname.namespace" -}}
{{- printf "%s-%s" (include "common.names.fullname.namespace" .) "cleanup-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Reports Controller fullname
*/}}
{{- define "kyverno.reports-controller.fullname" -}}
{{- printf "%s-%s" (include "common.names.fullname" .) "reports-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Kyverno Reports Controller fullname (namespace)
*/}}
{{- define "kyverno.reports-controller.fullname.namespace" -}}
{{- printf "%s-%s" (include "common.names.fullname.namespace" .) "reports-controller" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Add all images Return the proper Docker Image Registry Secret Names
*/}}
{{- define "kyverno.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.admissionController.image .Values.backgroundController.image .Values.cleanupController.image .Values.reportsController.image) "context" $) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names for the `imagePullSecrets` parameter in Kyverno
*/}}
{{- define "kyverno.imagePullSecrets.string" -}}
{{- $res := list -}}
{{- if .Values.global.imagePullSecrets -}}
{{- $res = concat $res .Values.global.imagePullSecrets -}}
{{- end -}}
{{- range (list .Values.admissionController.image .Values.backgroundController.image .Values.cleanupController.image .Values.reportsController.image) -}}
  {{- range .pullSecrets -}}
    {{- $res = append $res . -}}
  {{- end -}}
{{- end -}}
{{- if gt (len $res) 0 -}}
{{- join "," $res -}}
{{- end -}}
{{- end -}}

{{- define "kyverno.features.flags" -}}
{{- /*
    Directly taken from upstream Kyverno chart
    Source: https://github.com/kyverno/kyverno/blob/main/charts/kyverno/templates/_helpers.tpl#L11
    */ -}}
{{- $flags := list -}}
{{- with .admissionReports -}}
  {{- $flags = append $flags (print "--admissionReports=" .enabled) -}}
  {{- with .backPressureThreshold -}}
    {{- $flags = append $flags (print "--maxAdmissionReports=" .) -}}
  {{- end -}}
{{- end -}}
{{- with .aggregateReports -}}
  {{- $flags = append $flags (print "--aggregateReports=" .enabled) -}}
{{- end -}}
{{- with .policyReports -}}
  {{- $flags = append $flags (print "--policyReports=" .enabled) -}}
{{- end -}}
{{- with .validatingAdmissionPolicyReports -}}
  {{- $flags = append $flags (print "--validatingAdmissionPolicyReports=" .enabled) -}}
{{- end -}}
{{- with .mutatingAdmissionPolicyReports -}}
  {{- $flags = append $flags (print "--mutatingAdmissionPolicyReports=" .enabled) -}}
{{- end -}}
{{- with .autoUpdateWebhooks -}}
  {{- $flags = append $flags (print "--autoUpdateWebhooks=" .enabled) -}}
{{- end -}}
{{- with .autoDeleteWebhooks }}
  {{- $flags = append $flags (print "--autoDeleteWebhooks=" .enabled) -}}
{{- end }}
{{- with .backgroundScan -}}
  {{- $flags = append $flags (print "--backgroundScan=" .enabled) -}}
  {{- $flags = append $flags (print "--backgroundScanWorkers=" .backgroundScanWorkers) -}}
  {{- $flags = append $flags (print "--backgroundScanInterval=" .backgroundScanInterval) -}}
  {{- $flags = append $flags (print "--skipResourceFilters=" .skipResourceFilters) -}}
{{- end -}}
{{- with .configMapCaching -}}
  {{- $flags = append $flags (print "--enableConfigMapCaching=" .enabled) -}}
{{- end -}}
{{- with .deferredLoading -}}
  {{- $flags = append $flags (print "--enableDeferredLoading=" .enabled) -}}
{{- end -}}
{{- with .dumpPayload -}}
  {{- $flags = append $flags (print "--dumpPayload=" .enabled) -}}
{{- end -}}
{{- with .forceFailurePolicyIgnore -}}
  {{- $flags = append $flags (print "--forceFailurePolicyIgnore=" .enabled) -}}
{{- end -}}
{{- with .generateValidatingAdmissionPolicy -}}
  {{- $flags = append $flags (print "--generateValidatingAdmissionPolicy=" .enabled) -}}
{{- end -}}
{{- with .generateMutatingAdmissionPolicy -}}
  {{- $flags = append $flags (print "--generateMutatingAdmissionPolicy=" .enabled) -}}
{{- end -}}
{{- with .dumpPatches -}}
  {{- $flags = append $flags (print "--dumpPatches=" .enabled) -}}
{{- end -}}
{{- with .globalContext -}}
  {{- $flags = append $flags (print "--maxAPICallResponseLength=" (int .maxApiCallResponseLength)) -}}
{{- end -}}
{{- with .logging -}}
  {{- $flags = append $flags (print "--loggingFormat=" .format) -}}
  {{- $flags = append $flags (print "--v=" .verbosity) -}}
{{- end -}}
{{- with .omitEvents -}}
  {{- with .eventTypes -}}
    {{- $flags = append $flags (print "--omitEvents=" (join "," .)) -}}
  {{- end -}}
{{- end -}}
{{- with .policyExceptions -}}
  {{- $flags = append $flags (print "--enablePolicyException=" .enabled) -}}
  {{- with .namespace -}}
    {{- $flags = append $flags (print "--exceptionNamespace=" .) -}}
  {{- end -}}
{{- end -}}
{{- with .protectManagedResources -}}
  {{- $flags = append $flags (print "--protectManagedResources=" .enabled) -}}
{{- end -}}
{{- with .registryClient -}}
  {{- $flags = append $flags (print "--allowInsecureRegistry=" .allowInsecure) -}}
  {{- $flags = append $flags (print "--registryCredentialHelpers=" (join "," .credentialHelpers)) -}}
{{- end -}}
{{- with .ttlController -}}
  {{- $flags = append $flags (print "--ttlReconciliationInterval=" .reconciliationInterval) -}}
{{- end -}}
{{- with .tuf -}}
  {{- with .enabled -}}
    {{- $flags = append $flags (print "--enableTuf=" .) -}}
  {{- end -}}
  {{- with .mirror -}}
    {{- $flags = append $flags (print "--tufMirror=" .) -}}
  {{- end -}}
  {{- with .root -}}
    {{- $flags = append $flags (print "--tufRoot=" .) -}}
  {{- end -}}
  {{- with .rootRaw -}}
    {{- $flags = append $flags (print "--tufRootRaw=" .) -}}
  {{- end -}}
{{- end -}}
{{- with .reporting -}}
  {{- $reportingConfig := list -}}
  {{- with .validate -}}
    {{- $reportingConfig = append $reportingConfig "validate" -}}
  {{- end -}}
  {{- with .mutate -}}
    {{- $reportingConfig = append $reportingConfig "mutate" -}}
  {{- end -}}
  {{- with .mutateExisting -}}
    {{- $reportingConfig = append $reportingConfig "mutateExisting" -}}
  {{- end -}}
  {{- with .imageVerify -}}
    {{- $reportingConfig = append $reportingConfig "imageVerify" -}}
  {{- end -}}
  {{- with .generate -}}
    {{- $reportingConfig = append $reportingConfig "generate" -}}
  {{- end -}}
  {{- $flags = append $flags (print "--enableReporting=" (join "," $reportingConfig)) -}}
{{- end -}}
{{- with $flags -}}
  {{- toYaml . -}}
{{- end -}}
{{- end -}}

{{/*
Get the name of the TLS secret (Admission Controller)
*/}}
{{- define "kyverno.admission-controller.tlsSecretName" -}}
{{- if or .Values.kyverno.tls.autoGenerated.enabled (and (not (empty .Values.admissionController.tls.cert)) (not (empty .Values.admissionController.tls.key))) -}}
    {{- printf "%s-crt" (include "kyverno.admission-controller.fullname" .) -}}
{{- else -}}
    {{- required "An existing secret name must be provided with TLS certs for Kyverno admission controller if cert and key are not provided!" (tpl .Values.admissionController.tls.existingSecret .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the name of the TLS secret (Cleanup Controller)
*/}}
{{- define "kyverno.cleanup-controller.tlsSecretName" -}}
{{- if or .Values.kyverno.tls.autoGenerated.enabled (and (not (empty .Values.cleanupController.tls.cert)) (not (empty .Values.cleanupController.tls.key))) -}}
    {{- printf "%s-crt" (include "kyverno.cleanup-controller.fullname" .) -}}
{{- else -}}
    {{- required "An existing secret name must be provided with TLS certs for Kyverno cleanup controller if cert and key are not provided!" (tpl .Values.cleanupController.tls.existingSecret .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the CA TLS certificate
*/}}
{{- define "kyverno.tlsCASecretName" -}}
{{- if or .Values.kyverno.tls.autoGenerated.enabled (and (not (empty .Values.kyverno.tls.CACert)) (not (empty .Values.kyverno.tls.CAKey))) -}}
    {{- printf "%s-ca" (include "common.names.fullname" .) -}}
{{- else -}}
    {{- required "An existing secret name must be provided with CATLS certs for Kyverno if CA cert and CA key are not provided!" (tpl .Values.kyverno.tls.existingCASecret .) -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (Admission Controller)
*/}}
{{- define "kyverno.admission-controller.serviceAccountName" -}}
{{- if .Values.admissionController.serviceAccount.create -}}
    {{ default (include "kyverno.admission-controller.fullname" .) .Values.admissionController.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.admissionController.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (Background Controller)
*/}}
{{- define "kyverno.background-controller.serviceAccountName" -}}
{{- if .Values.backgroundController.serviceAccount.create -}}
    {{ default (include "kyverno.background-controller.fullname" .) .Values.backgroundController.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.backgroundController.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (Cleanup Controller)
*/}}
{{- define "kyverno.cleanup-controller.serviceAccountName" -}}
{{- if .Values.cleanupController.serviceAccount.create -}}
    {{ default (include "kyverno.cleanup-controller.fullname" .) .Values.cleanupController.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.cleanupController.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use (reports controller)
*/}}
{{- define "kyverno.reports-controller.serviceAccountName" -}}
{{- if .Values.reportsController.serviceAccount.create -}}
    {{ default (include "kyverno.reports-controller.fullname" .) .Values.reportsController.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.reportsController.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get the Kyverno configuration configmap.
*/}}
{{- define "kyverno.config.configmapName" -}}
{{- if .Values.kyverno.existingConfigmap -}}
    {{- tpl .Values.kyverno.existingConfigmap $ -}}
{{- else }}
    {{- include "common.names.fullname" . -}}
{{- end -}}
{{- end -}}


{{/*
Get the Kyverno metrics configuration configmap.
*/}}
{{- define "kyverno.metrics-config.configmapName" -}}
{{- if .Values.metrics.existingConfigmap -}}
    {{- tpl .Values.metrics.existingConfigmap $ -}}
{{- else }}
    {{- printf "%s-%s" (include "common.names.fullname" .) "metrics" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "kyverno.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.admissionController.image }}
{{- include "common.warnings.rollingTag" .Values.backgroundController.image }}
{{- include "common.warnings.rollingTag" .Values.cleanupController.image }}
{{- include "common.warnings.rollingTag" .Values.reportsController.image }}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "kyverno.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "kyverno.validateValues.tls" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Kyverno - TLS */}}
{{- define "kyverno.validateValues.tls" -}}
{{- if and (not .Values.kyverno.tls.autoGenerated.enabled) (not .Values.kyverno.tls.caCert) (not .Values.kyverno.tls.caKey) (not .Values.kyverno.tls.existingCASecret) -}}
kyverno: CA TLS
    You need to provide a TLS configuration for the CA. Please set either kyverno.tls.autoGenerated.enabled or set the kyverno.tls.caCert, kyverno.tls.caKey or kyverno.tls.existingSecret values
{{- end -}}
{{- if and (not .Values.kyverno.tls.autoGenerated.enabled) (not .Values.admissionController.tls.cert) (not .Values.admissionController.tls.key) (not .Values.admissionController.tls.existingSecret) -}}
kyverno: Admission Controller TLS
    You need to provide a TLS configuration for the Admission Controller. Please set either kyverno.tls.autoGenerated.enabled or set the admissionController.tls.caCert, admissionController.tls.caKey or admissionController.tls.existingSecret values
{{- end -}}
{{- if and .Values.cleanupController.enabled (not .Values.kyverno.tls.autoGenerated.enabled) (not .Values.admissionController.tls.cert) (not .Values.admissionController.tls.key) (not .Values.admissionController.tls.existingSecret) -}}
kyverno: Cleanup Controller TLS
    You need to provide a TLS configuration for the Cleanup Controller. Please set either kyverno.tls.autoGenerated.enabled or set the cleanupController.tls.caCert, cleanupController.tls.caKey or cleanupController.tls.existingSecret values
{{- end -}}
{{- end -}}

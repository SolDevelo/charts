<!--- app-name: Versity S3 Gateway -->

# Bitnami Secure Images Helm chart for Versity S3 Gateway

 Versity S3 Gateway translates S3 API calls to backend storage systems like POSIX, ScoutFS, Azure Blob, and more.

[Overview of Versity S3 Gateway]( https://www.versity.com/products/versitygw/)

Trademarks: This software listing is packaged by Bitnami. The respective trademarks mentioned in the offering are owned by the respective companies, and use of them does not imply any affiliation or endorsement.

## TL;DR

```console
helm install my-release oci://MY-OCI-REGISTRY/versitygw
```

Looking to use Versity S3 Gateway in production? Try [VMware Tanzu Application Catalog](https://bitnami.com/enterprise), the commercial edition of the Bitnami catalog.

## Introduction

This chart bootstraps a Versity S3 Gateway deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release REGISTRY_NAME/REPOSITORY_NAME/versitygw
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamichartsprem`.

The command deploys Versity S3 Gateway on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Configuration and installation details

### Gateway configuration

All available [Versity S3 Gateway configuration parameters](https://github.com/versity/versitygw/blob/main/extra/example.conf) can be set by using the following parameters:

- `overrideConfiguration`: Set the non-sensitive configuration parameters, such as `VGW_QUIET`.
- `secretOverrideConfiguration`: Set the sensitive configuration parameters, such as `VGW_IAM_VAULT_ROLE_SECRET`.

In the following example, we update the health enpoint and configure the S3 IAM parameters:

```yaml
overrideConfiguration:
  VGW_HEALTH: /myendpoint
secretOverrideConfiguration:
  VGW_S3_IAM_ACCESS_KEY: foo
  VGW_S3_IAM_SECRET_KEY: bar
  VGW_S3_IAM_REGION: us-east-1
  VGW_S3_IAM_ENDPOINT: https://s3-endpoint
  VGW_S3_IAM_BUCKET: my-bucket
```

### Update credentials

The Bitnami Versity S3 Gateway chart, when upgrading, reuses the secret previously rendered by the chart or the one specified in `existingSecret`. To update credentials, use one of the following:

- Run `helm upgrade` specifying a new access key secret in `auth.secretAccessKey`
- Run `helm upgrade` specifying a new secret in `existingSecret`

### Resource requests and limits

Bitnami charts allow setting resource requests and limits for all containers inside the chart deployment. These are inside the `resources` value (check parameter table). Setting requests is essential for production workloads and these should be adapted to your specific use case.

To make this process easier, the chart contains the `resourcesPreset` values, which automatically sets the `resources` section according to different presets. Check these presets in [the bitnami/common chart](https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15). However, in production workloads using `resourcesPreset` is discouraged as it may not fully adapt to your specific needs. Find more information on container resource management in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).

### FIPS parameters

The FIPS parameters only have effect if you are using images from the [Bitnami Secure Images catalog](https://www.arrow.com/globalecs/uk/products/bitnami-secure-images/).

### Backup and restore

To back up and restore Helm chart deployments on Kubernetes, you need to back up the persistent volumes from the source deployment and attach them to a new deployment using [Velero](https://velero.io/), a Kubernetes backup/restore tool. Find the instructions for using Velero in [this guide](https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-backup-restore-deployments-velero-index.html).

### [Rolling VS Immutable tags](https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html)

It is strongly recommended to use immutable tags in a production environment. This ensures your deployment does not change automatically if the same tag is updated with a different image.

Bitnami will release a new chart updating its containers if a new version of the main container, significant changes, or critical vulnerabilities exist.

### Additional environment variables

In case you want to add extra environment variables (useful for advanced operations like custom init scripts), you can use the `extraEnvVars` property:

```yaml
extraEnvVars:
  - name: LOG_LEVEL
    value: error
```

Alternatively, you can use a ConfigMap or a Secret with the environment variables. To do so, use the `extraEnvVarsCM` or the `extraEnvVarsSecret` values (also the one inside the `webhooks` section).

### Sidecars

If additional containers are needed in the same pod as versitygw (such as additional metrics or logging exporters), they can be defined using the `sidecars` parameter:

```yaml
sidecars:
- name: your-image-name
  image: your-image
  imagePullPolicy: Always
  ports:
  - name: portname
    containerPort: 1234
```

If these sidecars export extra ports, extra port definitions can be added using the `service.extraPorts` parameter (where available), as shown in the example below:

```yaml
service:
  extraPorts:
  - name: extraPort
    port: 11311
    targetPort: 11311
```

If additional init containers are needed in the same pod, they can be defined using the `initContainers` parameter. Here is an example:

```yaml
initContainers:
  - name: your-image-name
    image: your-image
    imagePullPolicy: Always
    ports:
      - name: portname
        containerPort: 1234
```

Learn more about [sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/) and [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).

### Ingress

This chart provides support for Ingress resources. If you have an ingress controller installed on your cluster, such as [nginx-ingress-controller](https://github.com/bitnami/charts/tree/main/bitnami/nginx-ingress-controller) or [contour](https://github.com/bitnami/charts/tree/main/bitnami/contour) you can utilize the ingress controller to serve your application. To enable Ingress integration, set `ingress.enabled` to `true`.

The most common scenario is to have one host name mapped to the deployment. In this case, the `ingress.hostname` property can be used to set the host name. The `ingress.tls` parameter can be used to add the TLS configuration for this host.

However, it is also possible to have more than one host. To facilitate this, the `ingress.extraHosts` parameter (if available) can be set with the host names specified as an array. The `ingress.extraTLS` parameter (if available) can also be used to add the TLS configuration for extra hosts.

> NOTE: For each host specified in the `ingress.extraHosts` parameter, it is necessary to set a name, path, and any annotations that the Ingress controller should know about. Not all annotations are supported by all Ingress controllers, but [this annotation reference document](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md) lists the annotations supported by many popular Ingress controllers.

Adding the TLS parameter (where available) will cause the chart to generate HTTPS URLs, and the application will be available on port 443. The actual TLS secrets do not have to be generated by this chart. However, if TLS is enabled, the Ingress record will not work until the TLS secret exists.

[Learn more about Ingress controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

### Securing traffic using TLS

By default, this chart assumes TLS is managed by the Ingress Controller and terminates the TLS connection in the Ingress Controller. This can be done by setting `ingress.enabled` and `ingress.tls` parameters to `true` as explained in the section above. However, it is possible to configure TLS encryption for Versity S3 Gateway directly by setting `tls.enabled` parameter to `true`.

It is necessary to create a secret containing the TLS certificates and pass it to the chart via the `tls.existingSecret` parameter. The secret should contain a `tls.crt` and `tls.key` keys including the certificate and key files respectively.

You can manually create the required TLS certificates or relying on the chart auto-generation capabilities. The chart supports two different ways to auto-generate the required certificates:

- Using Helm capabilities. Enable this feature by setting `tls.autoGenerated.enabled` to `true` and `tls.autoGenerated.engine` to `helm`.
- Relying on CertManager (please note it's required to have CertManager installed in your K8s cluster). Enable this feature by setting `tls.autoGenerated.enabled` to `true` and `tls.autoGenerated.engine` to `cert-manager`. Please note it's supported to use an existing Issuer/ClusterIssuer for issuing the TLS certificates by setting the `tls.autoGenerated.certManager.existingIssuer` and `tls.autoGenerated.certManager.existingIssuerKind` parameters.

### Deploying extra resources

There are cases where you may want to deploy extra objects, such a ConfigMap containing your app's configuration or some extra deployment with a micro service used by your app. For covering this case, the chart allows adding the full specification of other objects using the `extraDeploy` parameter.

### Pod affinity

This chart allows you to set your custom affinity using the `affinity` parameter. Find more information about Pod affinity in the [kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity).

As an alternative, use one of the preset configurations for pod affinity, pod anti-affinity, and node affinity available at the [bitnami/common](https://github.com/bitnami/charts/tree/main/bitnami/common#affinities) chart. To do so, set the `podAffinityPreset`, `podAntiAffinityPreset`, or `nodeAffinityPreset` parameters (also the one inside the `webhooks` section).

## Parameters

### Global parameters

| Name                                                  | Description                                                                                                                                                                                                                                                                                                                                                         | Value        |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `global.imageRegistry`                                | Global Docker image registry                                                                                                                                                                                                                                                                                                                                        | `""`         |
| `global.imagePullSecrets`                             | Global Docker registry secret names as an array                                                                                                                                                                                                                                                                                                                     | `[]`         |
| `global.defaultStorageClass`                          | Global default StorageClass for Persistent Volume(s)                                                                                                                                                                                                                                                                                                                | `""`         |
| `global.defaultFips`                                  | Default value for the FIPS configuration (allowed values: '', restricted, relaxed, off). Can be overriden by the 'fips' object                                                                                                                                                                                                                                      | `restricted` |
| `global.security.allowInsecureImages`                 | Allows skipping image verification                                                                                                                                                                                                                                                                                                                                  | `false`      |
| `global.compatibility.openshift.adaptSecurityContext` | Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC: remove runAsUser, runAsGroup and fsGroup and let the platform use their allowed default IDs. Possible values: auto (apply if the detected running cluster is Openshift), force (perform the adaptation always), disabled (do not perform adaptation) | `auto`       |

### Common parameters

| Name                                                | Description                                                                                                                                                                                                           | Value                       |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| `kubeVersion`                                       | Override Kubernetes version                                                                                                                                                                                           | `""`                        |
| `apiVersions`                                       | Override Kubernetes API versions reported by .Capabilities                                                                                                                                                            | `[]`                        |
| `nameOverride`                                      | String to partially override common.names.name                                                                                                                                                                        | `""`                        |
| `fullnameOverride`                                  | String to fully override common.names.fullname                                                                                                                                                                        | `""`                        |
| `namespaceOverride`                                 | String to fully override common.names.namespace                                                                                                                                                                       | `""`                        |
| `commonLabels`                                      | Labels to add to all deployed objects                                                                                                                                                                                 | `{}`                        |
| `commonAnnotations`                                 | Annotations to add to all deployed objects                                                                                                                                                                            | `{}`                        |
| `clusterDomain`                                     | Kubernetes cluster domain name                                                                                                                                                                                        | `cluster.local`             |
| `extraDeploy`                                       | Array of extra objects to deploy with the release                                                                                                                                                                     | `[]`                        |
| `diagnosticMode.enabled`                            | Enable diagnostic mode (all probes will be disabled and the command will be overridden)                                                                                                                               | `false`                     |
| `diagnosticMode.command`                            | Command to override all containers in the deployment                                                                                                                                                                  | `["sleep"]`                 |
| `diagnosticMode.args`                               | Args to override all containers in the deployment                                                                                                                                                                     | `["infinity"]`              |
| `image.registry`                                    | versitygw image registry                                                                                                                                                                                              | `REGISTRY_NAME`             |
| `image.repository`                                  | versitygw image repository                                                                                                                                                                                            | `REPOSITORY_NAME/versitygw` |
| `image.digest`                                      | versitygw image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended)                                                                  | `""`                        |
| `image.pullPolicy`                                  | versitygw image pull policy                                                                                                                                                                                           | `IfNotPresent`              |
| `image.pullSecrets`                                 | versitygw image pull secrets                                                                                                                                                                                          | `[]`                        |
| `replicaCount`                                      | Number of versitygw replicas to deploy                                                                                                                                                                                | `1`                         |
| `containerPorts.http`                               | versitygw server container port. When setting tls.enabled=true it will use https                                                                                                                                      | `7070`                      |
| `extraContainerPorts`                               | Optionally specify extra list of additional ports                                                                                                                                                                     | `[]`                        |
| `livenessProbe.enabled`                             | Enable livenessProbe on versitygw containers                                                                                                                                                                          | `true`                      |
| `livenessProbe.initialDelaySeconds`                 | Initial delay seconds for livenessProbe                                                                                                                                                                               | `5`                         |
| `livenessProbe.periodSeconds`                       | Period seconds for livenessProbe                                                                                                                                                                                      | `10`                        |
| `livenessProbe.timeoutSeconds`                      | Timeout seconds for livenessProbe                                                                                                                                                                                     | `5`                         |
| `livenessProbe.failureThreshold`                    | Failure threshold for livenessProbe                                                                                                                                                                                   | `5`                         |
| `livenessProbe.successThreshold`                    | Success threshold for livenessProbe                                                                                                                                                                                   | `1`                         |
| `readinessProbe.enabled`                            | Enable readinessProbe on versitygw containers                                                                                                                                                                         | `true`                      |
| `readinessProbe.initialDelaySeconds`                | Initial delay seconds for readinessProbe                                                                                                                                                                              | `5`                         |
| `readinessProbe.periodSeconds`                      | Period seconds for readinessProbe                                                                                                                                                                                     | `10`                        |
| `readinessProbe.timeoutSeconds`                     | Timeout seconds for readinessProbe                                                                                                                                                                                    | `5`                         |
| `readinessProbe.failureThreshold`                   | Failure threshold for readinessProbe                                                                                                                                                                                  | `5`                         |
| `readinessProbe.successThreshold`                   | Success threshold for readinessProbe                                                                                                                                                                                  | `1`                         |
| `startupProbe.enabled`                              | Enable startupProbe on versitygw containers                                                                                                                                                                           | `false`                     |
| `startupProbe.initialDelaySeconds`                  | Initial delay seconds for startupProbe                                                                                                                                                                                | `5`                         |
| `startupProbe.periodSeconds`                        | Period seconds for startupProbe                                                                                                                                                                                       | `10`                        |
| `startupProbe.timeoutSeconds`                       | Timeout seconds for startupProbe                                                                                                                                                                                      | `5`                         |
| `startupProbe.failureThreshold`                     | Failure threshold for startupProbe                                                                                                                                                                                    | `5`                         |
| `startupProbe.successThreshold`                     | Success threshold for startupProbe                                                                                                                                                                                    | `1`                         |
| `customLivenessProbe`                               | Custom livenessProbe that overrides the default one                                                                                                                                                                   | `{}`                        |
| `customReadinessProbe`                              | Custom readinessProbe that overrides the default one                                                                                                                                                                  | `{}`                        |
| `customStartupProbe`                                | Custom startupProbe that overrides the default one                                                                                                                                                                    | `{}`                        |
| `backend`                                           | Define versitygw backend                                                                                                                                                                                              | `posix`                     |
| `overrideConfiguration`                             | Override default configuration settings                                                                                                                                                                               | `{}`                        |
| `existingConfigMap`                                 | Name of a ConfigMap with configuration settings                                                                                                                                                                       | `""`                        |
| `secretOverrideConfiguration`                       | Override sensitive default configuration settings                                                                                                                                                                     | `{}`                        |
| `existingSecret`                                    | Name of a Secret with sensitive configuration settings                                                                                                                                                                | `""`                        |
| `extraArgs`                                         | Add extra arguments to the default command                                                                                                                                                                            | `""`                        |
| `usePasswordFiles`                                  | Mount all sensitive information as files                                                                                                                                                                              | `true`                      |
| `auth.accessKeyID`                                  | Auth access key ID                                                                                                                                                                                                    | `root`                      |
| `auth.secretAccessKey`                              | Auth secret access key                                                                                                                                                                                                | `""`                        |
| `resourcesPreset`                                   | Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if `resources` is set (`resources` is recommended for production). | `nano`                      |
| `resources`                                         | Set container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                     | `{}`                        |
| `fips.openssl`                                      | Configure OpenSSL FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                    | `""`                        |
| `fips.golang`                                       | Configure Golang FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                     | `relaxed`                   |
| `podSecurityContext.enabled`                        | Enabled versitygw pods' Security Context                                                                                                                                                                              | `true`                      |
| `podSecurityContext.fsGroupChangePolicy`            | Set filesystem group change policy                                                                                                                                                                                    | `Always`                    |
| `podSecurityContext.sysctls`                        | Set kernel settings using the sysctl interface                                                                                                                                                                        | `[]`                        |
| `podSecurityContext.supplementalGroups`             | Set filesystem extra groups                                                                                                                                                                                           | `[]`                        |
| `podSecurityContext.fsGroup`                        | Set versitygw pod's Security Context fsGroup                                                                                                                                                                          | `1001`                      |
| `containerSecurityContext.enabled`                  | Enabled containers' Security Context                                                                                                                                                                                  | `true`                      |
| `containerSecurityContext.seLinuxOptions`           | Set SELinux options in container                                                                                                                                                                                      | `{}`                        |
| `containerSecurityContext.runAsUser`                | Set containers' Security Context runAsUser                                                                                                                                                                            | `1001`                      |
| `containerSecurityContext.runAsGroup`               | Set containers' Security Context runAsGroup                                                                                                                                                                           | `1001`                      |
| `containerSecurityContext.runAsNonRoot`             | Set container's Security Context runAsNonRoot                                                                                                                                                                         | `true`                      |
| `containerSecurityContext.privileged`               | Set container's Security Context privileged                                                                                                                                                                           | `false`                     |
| `containerSecurityContext.readOnlyRootFilesystem`   | Set container's Security Context readOnlyRootFilesystem                                                                                                                                                               | `true`                      |
| `containerSecurityContext.allowPrivilegeEscalation` | Set container's Security Context allowPrivilegeEscalation                                                                                                                                                             | `false`                     |
| `containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped                                                                                                                                                                                    | `["ALL"]`                   |
| `containerSecurityContext.seccompProfile.type`      | Set container's Security Context seccomp profile                                                                                                                                                                      | `RuntimeDefault`            |
| `command`                                           | Override default container command (useful when using custom images)                                                                                                                                                  | `[]`                        |
| `args`                                              | Override default container args (useful when using custom images)                                                                                                                                                     | `[]`                        |
| `automountServiceAccountToken`                      | Mount Service Account token in pod                                                                                                                                                                                    | `false`                     |
| `hostAliases`                                       | versitygw pods host aliases                                                                                                                                                                                           | `[]`                        |
| `podLabels`                                         | Extra labels for versitygw pods                                                                                                                                                                                       | `{}`                        |
| `podAnnotations`                                    | Annotations for versitygw pods                                                                                                                                                                                        | `{}`                        |
| `podAffinityPreset`                                 | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                   | `""`                        |
| `podAntiAffinityPreset`                             | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                              | `soft`                      |
| `pdb.create`                                        | Enable/disable a Pod Disruption Budget creation                                                                                                                                                                       | `true`                      |
| `pdb.minAvailable`                                  | Minimum number/percentage of pods that should remain scheduled                                                                                                                                                        | `""`                        |
| `pdb.maxUnavailable`                                | Maximum number/percentage of pods that may be made unavailable                                                                                                                                                        | `""`                        |
| `nodeAffinityPreset.type`                           | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                             | `""`                        |
| `nodeAffinityPreset.key`                            | Node label key to match. Ignored if `affinity` is set                                                                                                                                                                 | `""`                        |
| `nodeAffinityPreset.values`                         | Node label values to match. Ignored if `affinity` is set                                                                                                                                                              | `[]`                        |
| `affinity`                                          | Affinity for versitygw pods assignment                                                                                                                                                                                | `{}`                        |
| `nodeSelector`                                      | Node labels for versitygw pods assignment                                                                                                                                                                             | `{}`                        |
| `tolerations`                                       | Tolerations for versitygw pods assignment                                                                                                                                                                             | `[]`                        |
| `updateStrategy.type`                               | versitygw statefulset strategy type                                                                                                                                                                                   | `RollingUpdate`             |
| `priorityClassName`                                 | versitygw pods' priorityClassName                                                                                                                                                                                     | `""`                        |
| `topologySpreadConstraints`                         | Topology Spread Constraints for pod assignment spread across your cluster among failure-domains. Evaluated as a template                                                                                              | `[]`                        |
| `schedulerName`                                     | Name of the k8s scheduler (other than default) for versitygw pods                                                                                                                                                     | `""`                        |
| `terminationGracePeriodSeconds`                     | Seconds Redmine pod needs to terminate gracefully                                                                                                                                                                     | `""`                        |
| `lifecycleHooks`                                    | for the versitygw container(s) to automate configuration before or after startup                                                                                                                                      | `{}`                        |
| `extraEnvVars`                                      | Array with extra environment variables to add to versitygw nodes                                                                                                                                                      | `[]`                        |
| `extraEnvVarsCM`                                    | Name of existing ConfigMap containing extra env vars for versitygw nodes                                                                                                                                              | `""`                        |
| `extraEnvVarsSecret`                                | Name of existing Secret containing extra env vars for versitygw nodes                                                                                                                                                 | `""`                        |
| `extraVolumes`                                      | Optionally specify extra list of additional volumes for the versitygw pod(s)                                                                                                                                          | `[]`                        |
| `extraVolumeMounts`                                 | Optionally specify extra list of additional volumeMounts for the versitygw container(s)                                                                                                                               | `[]`                        |
| `sidecars`                                          | Add additional sidecar containers to the versitygw pod(s)                                                                                                                                                             | `[]`                        |
| `initContainers`                                    | Add additional init containers to the versitygw pod(s)                                                                                                                                                                | `[]`                        |

### TLS/SSL parameters

| Name                                               | Description                                                                                                                                                            | Value     |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `tls.enabled`                                      | Enable TLS                                                                                                                                                             | `false`   |
| `tls.existingSecret`                               | Existing secret that contains TLS certificates                                                                                                                         | `""`      |
| `tls.certFilename`                                 | The secret key from the existing Secret if 'cert' key different from the default (tls.crt)                                                                             | `tls.crt` |
| `tls.certKeyFilename`                              | The secret key from the existing Secret if 'key' key different from the default (tls.key)                                                                              | `tls.key` |
| `tls.cert`                                         | TLS certificate. Ignored if `tls.existingSecret` is set                                                                                                                | `""`      |
| `tls.key`                                          | TLS key. Ignored if `tls.existingSecret` is set                                                                                                                        | `""`      |
| `tls.autoGenerated.enabled`                        | Enable automatic generation of TLS certificates                                                                                                                        | `true`    |
| `tls.autoGenerated.engine`                         | Mechanism to generate the certificates (allowed values: helm, cert-manager)                                                                                            | `helm`    |
| `tls.autoGenerated.extraSANs`                      | Extra Subject Alternative Names (SANs) for generated certificates                                                                                                      | `[]`      |
| `tls.autoGenerated.loopback`                       | Add loopback SANs (localhost and 127.0.0.1) to generated certificates                                                                                                  | `false`   |
| `tls.autoGenerated.certManager.existingIssuer`     | The name of an existing Issuer to use for generating the certificates (only for `cert-manager` engine)                                                                 | `""`      |
| `tls.autoGenerated.certManager.existingIssuerKind` | Existing Issuer kind, defaults to Issuer (only for `cert-manager` engine)                                                                                              | `""`      |
| `tls.autoGenerated.certManager.keyAlgorithm`       | Key algorithm for the certificates (only for `cert-manager` engine)                                                                                                    | `RSA`     |
| `tls.autoGenerated.certManager.keySize`            | Key size for the certificates (only for `cert-manager` engine)                                                                                                         | `2048`    |
| `tls.autoGenerated.certManager.duration`           | Duration for the certificates (only for `cert-manager` engine)                                                                                                         | `2160h`   |
| `tls.autoGenerated.certManager.renewBefore`        | Renewal period for the certificates (only for `cert-manager` engine)                                                                                                   | `360h`    |
| `autoscaling.vpa.enabled`                          | Enable VPA                                                                                                                                                             | `false`   |
| `autoscaling.vpa.annotations`                      | Annotations for VPA resource                                                                                                                                           | `{}`      |
| `autoscaling.vpa.controlledResources`              | VPA List of resources that the vertical pod autoscaler can control. Defaults to cpu and memory                                                                         | `[]`      |
| `autoscaling.vpa.maxAllowed`                       | VPA Max allowed resources for the pod                                                                                                                                  | `{}`      |
| `autoscaling.vpa.minAllowed`                       | VPA Min allowed resources for the pod                                                                                                                                  | `{}`      |
| `autoscaling.vpa.updatePolicy.updateMode`          | Autoscaling update policy Specifies whether recommended updates are applied when a Pod is started and whether recommended updates are applied during the life of a Pod | `Auto`    |
| `autoscaling.hpa.enabled`                          | Enable autoscaling for                                                                                                                                                 | `false`   |
| `autoscaling.hpa.minReplicas`                      | Minimum number of replicas                                                                                                                                             | `""`      |
| `autoscaling.hpa.maxReplicas`                      | Maximum number of replicas                                                                                                                                             | `""`      |
| `autoscaling.hpa.targetCPU`                        | Target CPU utilization percentage                                                                                                                                      | `""`      |
| `autoscaling.hpa.targetMemory`                     | Target Memory utilization percentage                                                                                                                                   | `""`      |

### Traffic Exposure Parameters

| Name                                          | Description                                                                                                                      | Value                    |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `service.type`                                | versitygw service type                                                                                                           | `LoadBalancer`           |
| `service.ports.http`                          | versitygw service server port                                                                                                    | `80`                     |
| `service.nodePorts.http`                      | Node port for the server                                                                                                         | `""`                     |
| `service.clusterIP`                           | versitygw service Cluster IP                                                                                                     | `""`                     |
| `service.loadBalancerIP`                      | versitygw service Load Balancer IP                                                                                               | `""`                     |
| `service.loadBalancerSourceRanges`            | versitygw service Load Balancer sources                                                                                          | `[]`                     |
| `service.externalTrafficPolicy`               | versitygw service external traffic policy                                                                                        | `Cluster`                |
| `service.labels`                              | Labels for the service                                                                                                           | `{}`                     |
| `service.annotations`                         | Additional custom annotations for versitygw service                                                                              | `{}`                     |
| `service.extraPorts`                          | Extra ports to expose in versitygw service (normally used with the `sidecars` value)                                             | `[]`                     |
| `service.sessionAffinity`                     | Control where web requests go, to the same pod or round-robin                                                                    | `None`                   |
| `service.sessionAffinityConfig`               | Additional settings for the sessionAffinity                                                                                      | `{}`                     |
| `ingress.enabled`                             | Enable ingress record generation for neo4j                                                                                       | `false`                  |
| `ingress.pathType`                            | Ingress path type                                                                                                                | `ImplementationSpecific` |
| `ingress.apiVersion`                          | Force Ingress API version (automatically detected if not set)                                                                    | `""`                     |
| `ingress.hostname`                            | Default host for the ingress record                                                                                              | `versitygw.local`        |
| `ingress.ingressClassName`                    | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                                                    | `""`                     |
| `ingress.path`                                | Default path for the ingress record                                                                                              | `/`                      |
| `ingress.annotations`                         | Additional annotations for the Ingress resource. To enable certificate autogeneration, place here your cert-manager annotations. | `{}`                     |
| `ingress.tls`                                 | Enable TLS configuration for the host defined at `ingress.hostname` parameter                                                    | `false`                  |
| `ingress.selfSigned`                          | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                     | `false`                  |
| `ingress.extraHosts`                          | An array with additional hostname(s) to be covered with the ingress record                                                       | `[]`                     |
| `ingress.extraPaths`                          | An array with additional arbitrary paths that may need to be added to the ingress under the main host                            | `[]`                     |
| `ingress.extraTls`                            | TLS configuration for additional hostname(s) to be covered with this ingress record                                              | `[]`                     |
| `ingress.secrets`                             | Custom TLS certificates as secrets                                                                                               | `[]`                     |
| `ingress.extraRules`                          | Additional rules to be covered with this ingress record                                                                          | `[]`                     |
| `networkPolicy.enabled`                       | Specifies whether a NetworkPolicy should be created                                                                              | `true`                   |
| `networkPolicy.allowExternal`                 | Don't require server label for connections                                                                                       | `true`                   |
| `networkPolicy.allowExternalEgress`           | Allow the pod to access any range of port and all destinations.                                                                  | `true`                   |
| `networkPolicy.extraIngress`                  | Add extra ingress rules to the NetworkPolicy                                                                                     | `[]`                     |
| `networkPolicy.extraEgress`                   | Add extra ingress rules to the NetworkPolicy                                                                                     | `[]`                     |
| `networkPolicy.ingressNSMatchLabels`          | Labels to match to allow traffic from other namespaces                                                                           | `{}`                     |
| `networkPolicy.ingressNSPodMatchLabels`       | Pod labels to match to allow traffic from other namespaces                                                                       | `{}`                     |
| `serviceAccount.create`                       | Specifies whether a ServiceAccount should be created                                                                             | `true`                   |
| `serviceAccount.name`                         | The name of the ServiceAccount to use.                                                                                           | `""`                     |
| `serviceAccount.annotations`                  | Additional Service Account annotations (evaluated as a template)                                                                 | `{}`                     |
| `serviceAccount.automountServiceAccountToken` | Automount service account token for the server service account                                                                   | `false`                  |

### Persistence Parameters

| Name                         | Description                                                                                                                           | Value                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| `persistence.enabled`        | Enable persistence using Persistent Volume Claims                                                                                     | `true`                    |
| `persistence.mountPath`      | Path to mount the volume at.                                                                                                          | `/bitnami/versitygw/data` |
| `persistence.subPath`        | The subdirectory of the volume to mount to, useful in dev environments and one PV for multiple services                               | `""`                      |
| `persistence.storageClass`   | Storage class of backing PVC                                                                                                          | `""`                      |
| `persistence.annotations`    | Persistent Volume Claim annotations                                                                                                   | `{}`                      |
| `persistence.accessModes`    | Persistent Volume Access Modes                                                                                                        | `["ReadWriteOnce"]`       |
| `persistence.size`           | Size of data volume                                                                                                                   | `8Gi`                     |
| `persistence.existingClaim`  | The name of an existing PVC to use for persistence                                                                                    | `""`                      |
| `persistence.selector`       | Selector to match an existing Persistent Volume for nessie data PVC                                                                   | `{}`                      |
| `persistence.dataSource`     | Custom PVC data source                                                                                                                | `{}`                      |
| `persistence.resourcePolicy` | Setting it to "keep" to avoid removing PVCs during a helm delete operation. Leaving it empty will delete PVCs after the chart deleted | `""`                      |

### Default init-containers

| Name                                                                                        | Description                                                                                                                                                                                                                                                                                                                            | Value                      |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `defaultInitContainers.volumePermissions.enabled`                                           | Enable init-container that changes the owner and group of the persistent volume                                                                                                                                                                                                                                                        | `false`                    |
| `defaultInitContainers.volumePermissions.image.registry`                                    | "volume-permissions" init-containers' image registry                                                                                                                                                                                                                                                                                   | `REGISTRY_NAME`            |
| `defaultInitContainers.volumePermissions.image.repository`                                  | "volume-permissions" init-containers' image repository                                                                                                                                                                                                                                                                                 | `REPOSITORY_NAME/os-shell` |
| `defaultInitContainers.volumePermissions.image.digest`                                      | "volume-permissions" init-containers' image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag                                                                                                                                                                                                  | `""`                       |
| `defaultInitContainers.volumePermissions.image.pullPolicy`                                  | "volume-permissions" init-containers' image pull policy                                                                                                                                                                                                                                                                                | `IfNotPresent`             |
| `defaultInitContainers.volumePermissions.image.pullSecrets`                                 | "volume-permissions" init-containers' image pull secrets                                                                                                                                                                                                                                                                               | `[]`                       |
| `defaultInitContainers.volumePermissions.containerSecurityContext.enabled`                  | Enable "volume-permissions" init-containers' Security Context                                                                                                                                                                                                                                                                          | `true`                     |
| `defaultInitContainers.volumePermissions.containerSecurityContext.seLinuxOptions`           | Set SELinux options in "volume-permissions" init-containers                                                                                                                                                                                                                                                                            | `{}`                       |
| `defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser`                | Set runAsUser in "volume-permissions" init-containers' Security Context                                                                                                                                                                                                                                                                | `0`                        |
| `defaultInitContainers.volumePermissions.containerSecurityContext.privileged`               | Set privileged in "volume-permissions" init-containers' Security Context                                                                                                                                                                                                                                                               | `false`                    |
| `defaultInitContainers.volumePermissions.containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation in "volume-permissions" init-containers' Security Context                                                                                                                                                                                                                                                 | `false`                    |
| `defaultInitContainers.volumePermissions.containerSecurityContext.capabilities.add`         | List of capabilities to be added in "volume-permissions" init-containers                                                                                                                                                                                                                                                               | `[]`                       |
| `defaultInitContainers.volumePermissions.containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped in "volume-permissions" init-containers                                                                                                                                                                                                                                                             | `["ALL"]`                  |
| `defaultInitContainers.volumePermissions.containerSecurityContext.seccompProfile.type`      | Set seccomp profile in "volume-permissions" init-containers                                                                                                                                                                                                                                                                            | `RuntimeDefault`           |
| `defaultInitContainers.volumePermissions.resourcesPreset`                                   | Set InfluxDB(TM) Core "volume-permissions" init-container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if defaultInitContainers.volumePermissions.resources is set (defaultInitContainers.volumePermissions.resources is recommended for production). | `nano`                     |
| `defaultInitContainers.volumePermissions.resources`                                         | Set InfluxDB(TM) Core "volume-permissions" init-container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                                                                          | `{}`                       |
| `defaultInitContainers.volumePermissions.fips.openssl`                                      | Configure OpenSSL FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                                                                                                                                     | `""`                       |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
helm install my-release \
  --set enableAPI=true \
    REGISTRY_NAME/REPOSITORY_NAME/versitygw
```

The above command enables the versitygw API Server.

> NOTE: Once this chart is deployed, it is not possible to change the application's access credentials, such as usernames or passwords, using Helm. To change these application credentials after deployment, delete any persistent volumes (PVs) used by the chart and re-deploy it, or use the application's built-in administrative tools if available.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm install my-release -f values.yaml REGISTRY_NAME/REPOSITORY_NAME/versitygw
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamichartsprem`.
> **Tip**: You can use the default [values.yaml](https://github.com/bitnami/charts-private/tree/main/bitnami/versitygw/values.yaml)

## Troubleshooting

Find more information about how to deal with common errors related to Bitnami's Helm charts in [this troubleshooting guide](https://docs.bitnami.com/general/how-to/troubleshoot-helm-chart-issues).

## License

Copyright &copy; 2025 Broadcom. The term "Broadcom" refers to Broadcom Inc. and/or its subsidiaries.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

<!--- app-name: Apache NiFi -->

# Bitnami package for Apache NiFi

Apache NiFi automates and manages data flows between systems using a visual interface for routing, transformation, and system mediation.

[Overview of Apache NiFi](https://nifi.apache.org/)

Trademarks: This software listing is packaged by Bitnami. The respective trademarks mentioned in the offering are owned by the respective companies, and use of them does not imply any affiliation or endorsement.

## TL;DR

```console
helm install my-release oci://registry-1.docker.io/bitnamicharts/nifi
```

Looking to use Apache NiFi in production? Try [VMware Tanzu Application Catalog](https://bitnami.com/enterprise), the commercial edition of the Bitnami catalog.

## Introduction

Bitnami charts for Helm are carefully engineered, actively maintained and are the quickest and easiest way to deploy containers on a Kubernetes cluster that are ready to handle production workloads.

This chart bootstraps a Apache NiFi deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://REGISTRY_NAME/REPOSITORY_NAME/nifi
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamicharts`.

The command deploys nifi on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Configuration and installation details

### [Rolling VS Immutable tags](https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-understand-rolling-tags-containers-index.html)

It is strongly recommended to use immutable tags in a production environment. This ensures your deployment does not change automatically if the same tag is updated with a different image.

Bitnami will release a new chart updating its containers if a new version of the main container, significant changes, or critical vulnerabilities exist.

### FIPS parameters

The FIPS parameters only have effect if you are using images from the [Bitnami Secure Images catalog](https://www.arrow.com/globalecs/uk/products/bitnami-secure-images/).

# Customizing Apache NiFi configuration files

All available [Apache NiFi](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#configuration-best-practices) configuration files can be modified using the following parameters:

- `configuration.overrideNifiProperties`: Override default values for the `nifi.properties` file.
- `configuration.nifiProperties`: Override the full `nifi.properties` file.
- `configuration.extraFiles`: Add extra configuration files to override the default ones (for example, `login-identitiy-providers.xml`).

In the following example, we change the default cluster configuration to use Zookeeper:

```yaml
configuration:
  overrideNifiProperties:
    nifi.state.management.provider.cluster: zk-provider
    nifi.zookeeper.connect.string: my-zk-0:3000
```

### Authentication

Bitnami NiFi chart sets [Single User Authentication](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#single_user_identity_provider) by default when setting `auth.enabled=true`. Configure the username and password using the `auth.username` and `auth.password`. In addition to this, it is possible to provide an existing secret using the `auth.existingSecret` value.

To update credentials, run `helm upgrade` with the new `username` and `password`.

It is also possible to configure other authentication methods by setting `auth.enabled=false` and configuring the `configuration.overrideNifiProperties` and the `configuration.extraFiles` parameter. The example below configures [LDAP](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#ldap_login_identity_provider) following the upstream documentation:

```yaml
configuration:
  overrideNifiProperties:
    nifi.security.user.login.identity.provider: ldap-provider
  extraFiles:
    login-identity-providers.xml: |
      <loginIdentityProviders>
        <provider>
            <identifier>ldap-provider</identifier>
            <class>org.apache.nifi.ldap.LdapProvider</class>
            <property name="Authentication Strategy">SIMPLE</property>

            <property name="Manager DN"></property>
            <property name="Manager Password"></property>

            <property name="TLS - Keystore">./conf/keystore.jks</property>
            <property name="TLS - Keystore Password">my_password</property>
            <property name="TLS - Keystore Type">jks</property>
            <property name="TLS - Truststore">./conf/truststore.jks</property>
            <property name="TLS - Truststore Password">my_password</property>
            <property name="TLS - Truststore Type">jks</property>
            <property name="TLS - Client Auth"></property>
            <property name="TLS - Protocol">TLSv1.2</property>
            <property name="TLS - Shutdown Gracefully"></property>

            <property name="Referral Strategy">FOLLOW</property>
            <property name="Connect Timeout">10 secs</property>
            <property name="Read Timeout">10 secs</property>

            <property name="Url">LDAP://ldap.my-site.com</property>
            <property name="User Search Base">OU=Standard Users,OU=Users,OU=US-Houston,OU=####,OU=Engineering,OU=Divisions,DC=####,DC=com</property>
            <property name="User Search Filter">sAMAccountName={0}</property>

            <property name="Identity Strategy">USE_USERNAME</property>
            <property name="Authentication Expiration">12 hours</property>
        </provider>
      </loginIdentityProviders>
```

It is possible to make some of the configuration values dependant on environment variables by setting them inside handlebars. In the example below we set the `nifi.nar.library.provider.hdfs.kerberos.password` property to depend on the environment variable `KERBEROS_PASSWORD`, configured via a secret called `my-kerberos-secret` (which should be configured using the `extraEnvVars` value):

```
extraEnvVars:
  - name: KERBEROS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: my-kerberos-secret
        key: password

configuration:
  overrideNifiProperties:
    # Use double-handlebars to workaround helm templating
    nifi.nar.library.provider.hdfs.kerberos.password: {{ "{{KERBEROS_PASSWORD}}" }}
```

### Ingress

This chart provides support for Ingress resources. If you have an ingress controller installed on your cluster, such as [nginx-ingress-controller](https://github.com/bitnami/charts/tree/main/bitnami/nginx-ingress-controller) or [contour](https://github.com/bitnami/charts/tree/main/bitnami/contour) you can utilize the ingress controller to serve your application. To enable Ingress integration, set `ingress.enabled` to `true`.

The most common scenario is to have one host name mapped to the deployment. In this case, the `ingress.hostname` property can be used to set the host name. The `ingress.tls` parameter can be used to add the TLS configuration for this host.

However, it is also possible to have more than one host. To facilitate this, the `ingress.extraHosts` parameter (if available) can be set with the host names specified as an array. The `ingress.extraTLS` parameter (if available) can also be used to add the TLS configuration for extra hosts.

> NOTE: For each host specified in the `ingress.extraHosts` parameter, it is necessary to set a name, path, and any annotations that the Ingress controller should know about. Not all annotations are supported by all Ingress controllers, but [this annotation reference document](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md) lists the annotations supported by many popular Ingress controllers.

Adding the TLS parameter (where available) will cause the chart to generate HTTPS URLs, and the application will be available on port 443. The actual TLS secrets do not have to be generated by this chart. However, if TLS is enabled, the Ingress record will not work until the TLS secret exists.

[Learn more about Ingress controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

### Securing traffic using TLS

Apache NiFi can encrypt communications by setting `tls.enabled=true`.

It is necessary to create a secret containing the TLS certificates and pass it to the chart via the `tls.existingSecret` parameter. The secret should contain a `tls.crt` and `tls.key` keys including the certificate and key files respectively.

You can manually create the required TLS certificates or relying on the chart auto-generation capabilities. The chart supports two different ways to auto-generate the required certificates:

- Using Helm capabilities. Enable this feature by setting `tls.autoGenerated.enabled` to `true` and `tls.autoGenerated.engine` to `helm`.
- Relying on CertManager (please note it's required to have CertManager installed in your K8s cluster). Enable this feature by setting `tls.autoGenerated.enabled` to `true` and `tls.autoGenerated.engine` to `cert-manager`. Please note it's supported to use an existing Issuer/ClusterIssuer for issuing the TLS certificates by setting the `tls.autoGenerated.certManager.existingIssuer` and `tls.autoGenerated.certManager.existingIssuerKind` parameters.

### Additional environment variables

In case you want to add extra environment variables (useful for advanced operations like custom init scripts), you can use the `extraEnvVars` property.

```yaml
extraEnvVars:
  - name: LOG_LEVEL
    value: error
```

Alternatively, you can use a ConfigMap or a Secret with the environment variables. To do so, use the `extraEnvVarsCM` or the `extraEnvVarsSecret` values.

### Sidecars

If additional containers are needed in the same pod as nifi (such as additional metrics or logging exporters), they can be defined using the `sidecars` parameter.

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

### Pod affinity

This chart allows you to set your custom affinity using the `affinity` parameter. Find more information about Pod affinity in the [kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity).

As an alternative, use one of the preset configurations for pod affinity, pod anti-affinity, and node affinity available at the [bitnami/common](https://github.com/bitnami/charts/tree/main/bitnami/common#affinities) chart. To do so, set the `podAffinityPreset`, `podAntiAffinityPreset`, or `nodeAffinityPreset` parameters.

### Backup and restore

To back up and restore Helm chart deployments on Kubernetes, you need to back up the persistent volumes from the source deployment and attach them to a new deployment using [Velero](https://velero.io/), a Kubernetes backup/restore tool. Find the instructions for using Velero in [this guide](https://techdocs.broadcom.com/us/en/vmware-tanzu/application-catalog/tanzu-application-catalog/services/tac-doc/apps-tutorials-backup-restore-deployments-velero-index.html).

## Persistence

The Bitnami NiFi image stores the nifi data and configurations at the `/bitnami` path of the container. Persistent Volume Claims are used to keep the data across deployments.

If you encounter errors when working with persistent volumes, refer to our [troubleshooting guide for persistent volumes](https://docs.bitnami.com/kubernetes/faq/troubleshooting/troubleshooting-persistence-volumes/).

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

| Name                     | Description                                                                             | Value           |
| ------------------------ | --------------------------------------------------------------------------------------- | --------------- |
| `kubeVersion`            | Override Kubernetes version                                                             | `""`            |
| `apiVersions`            | Override Kubernetes API versions reported by .Capabilities                              | `[]`            |
| `nameOverride`           | String to partially override common.names.name                                          | `""`            |
| `fullnameOverride`       | String to fully override common.names.fullname                                          | `""`            |
| `namespaceOverride`      | String to fully override common.names.namespace                                         | `""`            |
| `commonLabels`           | Labels to add to all deployed objects                                                   | `{}`            |
| `commonAnnotations`      | Annotations to add to all deployed objects                                              | `{}`            |
| `clusterDomain`          | Kubernetes cluster domain name                                                          | `cluster.local` |
| `extraDeploy`            | Array of extra objects to deploy with the release                                       | `[]`            |
| `usePasswordFiles`       | Mount credentials as files instead of using environment variables                       | `true`          |
| `diagnosticMode.enabled` | Enable diagnostic mode (all probes will be disabled and the command will be overridden) | `false`         |
| `diagnosticMode.command` | Command to override all containers in the chart release                                 | `["sleep"]`     |
| `diagnosticMode.args`    | Args to override all containers in the chart release                                    | `["infinity"]`  |

### NiFi Parameters

| Name                                                | Description                                                                                                                                                                                                     | Value                  |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| `image.registry`                                    | NiFi image registry                                                                                                                                                                                             | `REGISTRY_NAME`        |
| `image.repository`                                  | NiFi image repository                                                                                                                                                                                           | `REPOSITORY_NAME/nifi` |
| `image.digest`                                      | NiFi image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended)                                                                 | `""`                   |
| `image.pullPolicy`                                  | NiFi image pull policy                                                                                                                                                                                          | `IfNotPresent`         |
| `image.pullSecrets`                                 | NiFi image pull secrets                                                                                                                                                                                         | `[]`                   |
| `image.debug`                                       | Enable NiFi image debug mode                                                                                                                                                                                    | `false`                |
| `replicaCount`                                      | Number of replicas                                                                                                                                                                                              | `1`                    |
| `containerPorts.web`                                | NiFi web container port                                                                                                                                                                                         | `9443`                 |
| `containerPorts.cluster`                            | NiFi cluster container port                                                                                                                                                                                     | `11443`                |
| `containerPorts.loadBalance`                        | NiFi load balancer container port                                                                                                                                                                               | `6342`                 |
| `extraContainerPorts`                               | Optionally specify extra list of additional ports for NiFi containers                                                                                                                                           | `[]`                   |
| `webProxyHosts`                                     | list of allowed hostnames when tls.enabled=true                                                                                                                                                                 | `[]`                   |
| `configuration.nifiProperties`                      | Provide the full contents of nifi.properties to be overridden                                                                                                                                                   | `""`                   |
| `configuration.overrideNifiProperties`              | Override specific values of the default nifi.properties file                                                                                                                                                    | `{}`                   |
| `configuration.logToStdout`                         | Configure the logback.xml file to log everything to stdout                                                                                                                                                      | `true`                 |
| `configuration.extraFiles`                          | provide extra configuration files to override the default ones                                                                                                                                                  | `{}`                   |
| `configuration.existingSecret`                      | provide an existing secret with all the configuration files                                                                                                                                                     | `""`                   |
| `sensitiveProps.key`                                | set key for the nifi.sensitive.props.key property (auto-generated if not set)                                                                                                                                   | `""`                   |
| `sensitiveProps.existingSecret`                     | name of a secret containing the nifi.sensitive.props.key property                                                                                                                                               | `""`                   |
| `sensitiveProps.existingSecretKey`                  | name of the key inside the secret containing the nifi.sensitive.props.key property                                                                                                                              | `""`                   |
| `auth.enabled`                                      | Enable Single User authentication                                                                                                                                                                               | `true`                 |
| `auth.username`                                     | Name of the user for Single User Authentication                                                                                                                                                                 | `user`                 |
| `auth.password`                                     | Password for the user                                                                                                                                                                                           | `""`                   |
| `auth.existingSecretUsernameKey`                    | Name of a secret containing the Single User credentials                                                                                                                                                         | `""`                   |
| `auth.existingSecretPasswordKey`                    | Key inside the secret containing the password key                                                                                                                                                               | `""`                   |
| `livenessProbe.enabled`                             | Enable livenessProbe on NiFi containers                                                                                                                                                                         | `true`                 |
| `livenessProbe.initialDelaySeconds`                 | Initial delay seconds for livenessProbe                                                                                                                                                                         | `10`                   |
| `livenessProbe.periodSeconds`                       | Period seconds for livenessProbe                                                                                                                                                                                | `5`                    |
| `livenessProbe.timeoutSeconds`                      | Timeout seconds for livenessProbe                                                                                                                                                                               | `10`                   |
| `livenessProbe.failureThreshold`                    | Failure threshold for livenessProbe                                                                                                                                                                             | `20`                   |
| `livenessProbe.successThreshold`                    | Success threshold for livenessProbe                                                                                                                                                                             | `1`                    |
| `readinessProbe.enabled`                            | Enable readinessProbe on NiFi containers                                                                                                                                                                        | `true`                 |
| `readinessProbe.initialDelaySeconds`                | Initial delay seconds for readinessProbe                                                                                                                                                                        | `10`                   |
| `readinessProbe.periodSeconds`                      | Period seconds for readinessProbe                                                                                                                                                                               | `5`                    |
| `readinessProbe.timeoutSeconds`                     | Timeout seconds for readinessProbe                                                                                                                                                                              | `10`                   |
| `readinessProbe.failureThreshold`                   | Failure threshold for readinessProbe                                                                                                                                                                            | `20`                   |
| `readinessProbe.successThreshold`                   | Success threshold for readinessProbe                                                                                                                                                                            | `1`                    |
| `startupProbe.enabled`                              | Enable startupProbe on NiFi containers                                                                                                                                                                          | `false`                |
| `startupProbe.initialDelaySeconds`                  | Initial delay seconds for startupProbe                                                                                                                                                                          | `10`                   |
| `startupProbe.periodSeconds`                        | Period seconds for startupProbe                                                                                                                                                                                 | `5`                    |
| `startupProbe.timeoutSeconds`                       | Timeout seconds for startupProbe                                                                                                                                                                                | `10`                   |
| `startupProbe.failureThreshold`                     | Failure threshold for startupProbe                                                                                                                                                                              | `20`                   |
| `startupProbe.successThreshold`                     | Success threshold for startupProbe                                                                                                                                                                              | `1`                    |
| `customLivenessProbe`                               | Custom livenessProbe that overrides the default one                                                                                                                                                             | `{}`                   |
| `customReadinessProbe`                              | Custom readinessProbe that overrides the default one                                                                                                                                                            | `{}`                   |
| `customStartupProbe`                                | Custom startupProbe that overrides the default one                                                                                                                                                              | `{}`                   |
| `resourcesPreset`                                   | Set NiFi container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if resources is set (resources is recommended for production). | `medium`               |
| `resources`                                         | Set NiFi container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                          | `{}`                   |
| `fips.openssl`                                      | Configure OpenSSL FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                              | `""`                   |
| `fips.java`                                         | Configure JAVA FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                 | `relaxed`              |
| `podSecurityContext.enabled`                        | Enable NiFi pods' Security Context                                                                                                                                                                              | `true`                 |
| `podSecurityContext.fsGroupChangePolicy`            | Set filesystem group change policy for NiFi pods                                                                                                                                                                | `Always`               |
| `podSecurityContext.sysctls`                        | Set kernel settings using the sysctl interface for NiFi pods                                                                                                                                                    | `[]`                   |
| `podSecurityContext.supplementalGroups`             | Set filesystem extra groups for NiFi pods                                                                                                                                                                       | `[]`                   |
| `podSecurityContext.fsGroup`                        | Set fsGroup in NiFi pods' Security Context                                                                                                                                                                      | `1001`                 |
| `containerSecurityContext.enabled`                  | Enabled NiFi container' Security Context                                                                                                                                                                        | `true`                 |
| `containerSecurityContext.seLinuxOptions`           | Set SELinux options in NiFi container                                                                                                                                                                           | `{}`                   |
| `containerSecurityContext.runAsUser`                | Set runAsUser in NiFi container' Security Context                                                                                                                                                               | `1001`                 |
| `containerSecurityContext.runAsGroup`               | Set runAsGroup in NiFi container' Security Context                                                                                                                                                              | `1001`                 |
| `containerSecurityContext.runAsNonRoot`             | Set runAsNonRoot in NiFi container' Security Context                                                                                                                                                            | `true`                 |
| `containerSecurityContext.readOnlyRootFilesystem`   | Set readOnlyRootFilesystem in NiFi container' Security Context                                                                                                                                                  | `true`                 |
| `containerSecurityContext.privileged`               | Set privileged in NiFi container' Security Context                                                                                                                                                              | `false`                |
| `containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation in NiFi container' Security Context                                                                                                                                                | `false`                |
| `containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped in NiFi container                                                                                                                                                            | `["ALL"]`              |
| `containerSecurityContext.seccompProfile.type`      | Set seccomp profile in NiFi container                                                                                                                                                                           | `RuntimeDefault`       |
| `tls.enabled`                                       | Enable TLS                                                                                                                                                                                                      | `true`                 |
| `tls.existingSecret`                                | Name of a secret containing the certificate files                                                                                                                                                               | `""`                   |
| `tls.certCAFilename`                                | The secret key from the existing Secret if 'ca' key is different from the default (ca.crt)                                                                                                                      | `ca.crt`               |
| `tls.certFilename`                                  | The secret key from the existing Secret if 'cert' key is different from the default (tls.crt)                                                                                                                   | `tls.crt`              |
| `tls.certKeyFilename`                               | The secret key from the existing Secret if 'key' key is different from the default (tls.key)                                                                                                                    | `tls.key`              |
| `tls.ca`                                            | CA certificate for TLS. Ignored if `tls.existingSecret` is set                                                                                                                                                  | `""`                   |
| `tls.cert`                                          | TLS certificate. Ignored if `tls.existingSecret` is set                                                                                                                                                         | `""`                   |
| `tls.key`                                           | TLS key. Ignored if `tls.existingSecret` is set                                                                                                                                                                 | `""`                   |
| `tls.autoGenerated.enabled`                         | Enable automatic generation of TLS certificates                                                                                                                                                                 | `true`                 |
| `tls.autoGenerated.engine`                          | Mechanism to generate the certificates (allowed values: helm, cert-manager)                                                                                                                                     | `helm`                 |
| `tls.autoGenerated.extraSANs`                       | Extra Subject Alternative Names (SANs) for generated certificates                                                                                                                                               | `[]`                   |
| `tls.autoGenerated.loopback`                        | Add loopback SANs (localhost and 127.0.0.1) to generated certificates                                                                                                                                           | `false`                |
| `tls.autoGenerated.certManager.existingIssuer`      | The name of an existing Issuer to use for generating the certificates (only for `cert-manager` engine)                                                                                                          | `""`                   |
| `tls.autoGenerated.certManager.existingIssuerKind`  | Existing Issuer kind, defaults to Issuer (only for `cert-manager` engine)                                                                                                                                       | `""`                   |
| `tls.autoGenerated.certManager.keyAlgorithm`        | Key algorithm for the certificates (only for `cert-manager` engine)                                                                                                                                             | `RSA`                  |
| `tls.autoGenerated.certManager.keySize`             | Key size for the certificates (only for `cert-manager` engine)                                                                                                                                                  | `2048`                 |
| `tls.autoGenerated.certManager.duration`            | Duration for the certificates (only for `cert-manager` engine)                                                                                                                                                  | `2160h`                |
| `tls.autoGenerated.certManager.renewBefore`         | Renewal period for the certificates (only for `cert-manager` engine)                                                                                                                                            | `360h`                 |
| `command`                                           | Override default NiFi container command (useful when using custom images)                                                                                                                                       | `[]`                   |
| `args`                                              | Override default NiFi container args (useful when using custom images)                                                                                                                                          | `[]`                   |
| `automountServiceAccountToken`                      | Mount Service Account token in NiFi pods                                                                                                                                                                        | `true`                 |
| `hostAliases`                                       | NiFi pods host aliases                                                                                                                                                                                          | `[]`                   |
| `statefulsetAnnotations`                            | Annotations for NiFi statefulset                                                                                                                                                                                | `{}`                   |
| `podLabels`                                         | Extra labels for NiFi pods                                                                                                                                                                                      | `{}`                   |
| `podAnnotations`                                    | Annotations for NiFi pods                                                                                                                                                                                       | `{}`                   |
| `podAffinityPreset`                                 | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                             | `""`                   |
| `podAntiAffinityPreset`                             | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                        | `soft`                 |
| `nodeAffinityPreset.type`                           | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                       | `""`                   |
| `nodeAffinityPreset.key`                            | Node label key to match. Ignored if `affinity` is set                                                                                                                                                           | `""`                   |
| `nodeAffinityPreset.values`                         | Node label values to match. Ignored if `affinity` is set                                                                                                                                                        | `[]`                   |
| `affinity`                                          | Affinity for NiFi pods assignment                                                                                                                                                                               | `{}`                   |
| `nodeSelector`                                      | Node labels for NiFi pods assignment                                                                                                                                                                            | `{}`                   |
| `tolerations`                                       | Tolerations for NiFi pods assignment                                                                                                                                                                            | `[]`                   |
| `updateStrategy.type`                               | NiFi deployment strategy type                                                                                                                                                                                   | `RollingUpdate`        |
| `updateStrategy.type`                               | NiFi statefulset strategy type                                                                                                                                                                                  | `RollingUpdate`        |
| `podManagementPolicy`                               | Pod management policy for NiFi statefulset                                                                                                                                                                      | `OrderedReady`         |
| `priorityClassName`                                 | NiFi pods' priorityClassName                                                                                                                                                                                    | `""`                   |
| `topologySpreadConstraints`                         | Topology Spread Constraints for NiFi pod assignment spread across your cluster among failure-domains                                                                                                            | `[]`                   |
| `schedulerName`                                     | Name of the k8s scheduler (other than default) for NiFi pods                                                                                                                                                    | `""`                   |
| `terminationGracePeriodSeconds`                     | Seconds NiFi pods need to terminate gracefully                                                                                                                                                                  | `""`                   |
| `lifecycleHooks`                                    | for NiFi containers to automate configuration before or after startup                                                                                                                                           | `{}`                   |
| `extraEnvVars`                                      | Array with extra environment variables to add to NiFi containers                                                                                                                                                | `[]`                   |
| `extraEnvVarsCM`                                    | Name of existing ConfigMap containing extra env vars for NiFi containers                                                                                                                                        | `""`                   |
| `extraEnvVarsSecret`                                | Name of existing Secret containing extra env vars for NiFi containers                                                                                                                                           | `""`                   |
| `extraVolumes`                                      | Optionally specify extra list of additional volumes for the NiFi pods                                                                                                                                           | `[]`                   |
| `extraVolumeMounts`                                 | Optionally specify extra list of additional volumeMounts for the NiFi containers                                                                                                                                | `[]`                   |
| `sidecars`                                          | Add additional sidecar containers to the NiFi pods                                                                                                                                                              | `[]`                   |
| `initContainers`                                    | Add additional init containers to the NiFi pods                                                                                                                                                                 | `[]`                   |
| `pdb.create`                                        | Enable/disable a Pod Disruption Budget creation                                                                                                                                                                 | `true`                 |
| `pdb.minAvailable`                                  | Minimum number/percentage of pods that should remain scheduled                                                                                                                                                  | `""`                   |
| `pdb.maxUnavailable`                                | Maximum number/percentage of pods that may be made unavailable. Defaults to `1` if both `pdb.minAvailable` and `pdb.maxUnavailable` are empty.                                                                  | `""`                   |
| `autoscaling.hpa.enabled`                           | Enable HPA for NiFi pods                                                                                                                                                                                        | `false`                |
| `autoscaling.hpa.minReplicas`                       | Minimum number of replicas                                                                                                                                                                                      | `""`                   |
| `autoscaling.hpa.maxReplicas`                       | Maximum number of replicas                                                                                                                                                                                      | `""`                   |
| `autoscaling.hpa.targetCPU`                         | Target CPU utilization percentage                                                                                                                                                                               | `""`                   |
| `autoscaling.hpa.targetMemory`                      | Target Memory utilization percentage                                                                                                                                                                            | `""`                   |
| `autoscaling.vpa.enabled`                           | Enable VPA for NiFi pods                                                                                                                                                                                        | `false`                |
| `autoscaling.vpa.annotations`                       | Annotations for VPA resource                                                                                                                                                                                    | `{}`                   |
| `autoscaling.vpa.controlledResources`               | VPA List of resources that the vertical pod autoscaler can control. Defaults to cpu and memory                                                                                                                  | `[]`                   |
| `autoscaling.vpa.maxAllowed`                        | VPA Max allowed resources for the pod                                                                                                                                                                           | `{}`                   |
| `autoscaling.vpa.minAllowed`                        | VPA Min allowed resources for the pod                                                                                                                                                                           | `{}`                   |
| `autoscaling.vpa.updatePolicy.updateMode`           | Autoscaling update policy                                                                                                                                                                                       | `Auto`                 |

### Traffic Exposure Parameters

| Name                                        | Description                                                                                                                      | Value                    |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `service.type`                              | NiFi service type                                                                                                                | `LoadBalancer`           |
| `service.ports.web`                         | NiFi service web port                                                                                                            | `443`                    |
| `service.ports.loadBalance`                 | NiFi service load balance port                                                                                                   | `6342`                   |
| `service.nodePorts.web`                     | Node port for web                                                                                                                | `""`                     |
| `service.nodePorts.loadBalance`             | Node port for cluster                                                                                                            | `""`                     |
| `service.clusterIP`                         | NiFi service Cluster IP                                                                                                          | `""`                     |
| `service.loadBalancerIP`                    | NiFi service Load Balancer IP                                                                                                    | `""`                     |
| `service.loadBalancerSourceRanges`          | NiFi service Load Balancer sources                                                                                               | `[]`                     |
| `service.externalTrafficPolicy`             | NiFi service external traffic policy                                                                                             | `Cluster`                |
| `service.annotations`                       | Additional custom annotations for NiFi service                                                                                   | `{}`                     |
| `service.extraPorts`                        | Extra ports to expose in NiFi service (normally used with the `sidecars` value)                                                  | `[]`                     |
| `service.sessionAffinity`                   | Control where client requests go, to the same pod or round-robin                                                                 | `None`                   |
| `service.sessionAffinityConfig`             | Additional settings for the sessionAffinity                                                                                      | `{}`                     |
| `service.headless.annotations`              | Annotations for the headless service.                                                                                            | `{}`                     |
| `service.headless.publishNotReadyAddresses` | Publishes the addresses of not ready Pods                                                                                        | `true`                   |
| `networkPolicy.enabled`                     | Specifies whether a NetworkPolicy should be created                                                                              | `true`                   |
| `networkPolicy.allowExternal`               | Don't require server label for connections                                                                                       | `true`                   |
| `networkPolicy.allowExternalEgress`         | Allow the pod to access any range of port and all destinations.                                                                  | `true`                   |
| `networkPolicy.addExternalClientAccess`     | Allow access from pods with client label set to "true". Ignored if `networkPolicy.allowExternal` is true.                        | `true`                   |
| `networkPolicy.extraIngress`                | Add extra ingress rules to the NetworkPolicy                                                                                     | `[]`                     |
| `networkPolicy.extraEgress`                 | Add extra ingress rules to the NetworkPolicy (ignored if allowExternalEgress=true)                                               | `[]`                     |
| `networkPolicy.ingressPodMatchLabels`       | Labels to match to allow traffic from other pods. Ignored if `networkPolicy.allowExternal` is true.                              | `{}`                     |
| `networkPolicy.ingressNSMatchLabels`        | Labels to match to allow traffic from other namespaces. Ignored if `networkPolicy.allowExternal` is true.                        | `{}`                     |
| `networkPolicy.ingressNSPodMatchLabels`     | Pod labels to match to allow traffic from other namespaces. Ignored if `networkPolicy.allowExternal` is true.                    | `{}`                     |
| `ingress.enabled`                           | Enable ingress record generation for nifi                                                                                        | `false`                  |
| `ingress.pathType`                          | Ingress path type                                                                                                                | `ImplementationSpecific` |
| `ingress.apiVersion`                        | Force Ingress API version (automatically detected if not set)                                                                    | `""`                     |
| `ingress.hostname`                          | Default host for the ingress record                                                                                              | `nifi.local`             |
| `ingress.ingressClassName`                  | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                                                    | `""`                     |
| `ingress.path`                              | Default path for the ingress record                                                                                              | `/`                      |
| `ingress.annotations`                       | Additional annotations for the Ingress resource. To enable certificate autogeneration, place here your cert-manager annotations. | `{}`                     |
| `ingress.tls`                               | Enable TLS configuration for the host defined at `ingress.hostname` parameter                                                    | `false`                  |
| `ingress.selfSigned`                        | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                     | `false`                  |
| `ingress.extraHosts`                        | An array with additional hostname(s) to be covered with the ingress record                                                       | `[]`                     |
| `ingress.extraPaths`                        | An array with additional arbitrary paths that may need to be added to the ingress under the main host                            | `[]`                     |
| `ingress.extraTls`                          | TLS configuration for additional hostname(s) to be covered with this ingress record                                              | `[]`                     |
| `ingress.secrets`                           | Custom TLS certificates as secrets                                                                                               | `[]`                     |
| `ingress.extraRules`                        | Additional rules to be covered with this ingress record                                                                          | `[]`                     |

### Persistence Parameters

| Name                                                           | Description                                                                                             | Value               |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------- |
| `persistence.enabled`                                          | Enable persistence using Persistent Volume Claims                                                       | `true`              |
| `persistence.mountPath`                                        | Path to mount the volume at.                                                                            | `/bitnami/nifi`     |
| `persistence.subPath`                                          | The subdirectory of the volume to mount to, useful in dev environments and one PV for multiple services | `""`                |
| `persistence.storageClass`                                     | Storage class of backing PVC                                                                            | `""`                |
| `persistence.labels`                                           | Persistent Volume Claim labels                                                                          | `{}`                |
| `persistence.annotations`                                      | Persistent Volume Claim annotations                                                                     | `{}`                |
| `persistence.accessModes`                                      | Persistent Volume Access Modes                                                                          | `["ReadWriteOnce"]` |
| `persistence.size`                                             | Size of data volume                                                                                     | `8Gi`               |
| `persistence.selector`                                         | Selector to match an existing Persistent Volume for WordPress data PVC                                  | `{}`                |
| `persistence.persistentVolumeClaimRetentionPolicy.enabled`     | Controls if and how PVCs are deleted during the lifecycle of a StatefulSet                              | `false`             |
| `persistence.persistentVolumeClaimRetentionPolicy.whenScaled`  | Volume retention behavior when the replica count of the StatefulSet is reduced                          | `Retain`            |
| `persistence.persistentVolumeClaimRetentionPolicy.whenDeleted` | Volume retention behavior that applies when the StatefulSet is deleted                                  | `Retain`            |
| `persistence.extraVolumeClaimTemplates`                        | Optionally specify extra list of volumesClaimTemplates for the statefulset                              | `[]`                |

### Other Parameters

| Name                                          | Description                                                      | Value   |
| --------------------------------------------- | ---------------------------------------------------------------- | ------- |
| `rbac.create`                                 | Specifies whether RBAC resources should be created               | `true`  |
| `rbac.rules`                                  | Custom RBAC rules to set                                         | `[]`    |
| `serviceAccount.create`                       | Specifies whether a ServiceAccount should be created             | `true`  |
| `serviceAccount.name`                         | The name of the ServiceAccount to use.                           | `""`    |
| `serviceAccount.annotations`                  | Additional Service Account annotations (evaluated as a template) | `{}`    |
| `serviceAccount.automountServiceAccountToken` | Automount service account token for the server service account   | `false` |

### Init Container Parameters

| Name                                                                                   | Description                                                                                                                                                                                                                                                                                                    | Value                      |
| -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `defaultInitContainers.defaultImage.registry`                                          | OS Shell + Utility image registry                                                                                                                                                                                                                                                                              | `REGISTRY_NAME`            |
| `defaultInitContainers.defaultImage.repository`                                        | OS Shell + Utility image repository                                                                                                                                                                                                                                                                            | `REPOSITORY_NAME/os-shell` |
| `defaultInitContainers.defaultImage.pullPolicy`                                        | OS Shell + Utility image pull policy                                                                                                                                                                                                                                                                           | `IfNotPresent`             |
| `defaultInitContainers.defaultImage.pullSecrets`                                       | OS Shell + Utility image pull secrets                                                                                                                                                                                                                                                                          | `[]`                       |
| `defaultInitContainers.copyConfig.enabled`                                             | Enable the "copy-config" init container                                                                                                                                                                                                                                                                        | `true`                     |
| `defaultInitContainers.copyConfig.containerSecurityContext.enabled`                    | Enabled "copy-config" init-containers' Security Context                                                                                                                                                                                                                                                        | `true`                     |
| `defaultInitContainers.copyConfig.containerSecurityContext.seLinuxOptions`             | Set SELinux options in "copy-config" init-containers                                                                                                                                                                                                                                                           | `{}`                       |
| `defaultInitContainers.copyConfig.containerSecurityContext.runAsUser`                  | Set runAsUser in "copy-config" init-containers' Security Context                                                                                                                                                                                                                                               | `1001`                     |
| `defaultInitContainers.copyConfig.containerSecurityContext.runAsGroup`                 | Set runAsUser in "copy-config" init-containers' Security Context                                                                                                                                                                                                                                               | `1001`                     |
| `defaultInitContainers.copyConfig.containerSecurityContext.runAsNonRoot`               | Set runAsNonRoot in "copy-config" init-containers' Security Context                                                                                                                                                                                                                                            | `true`                     |
| `defaultInitContainers.copyConfig.containerSecurityContext.readOnlyRootFilesystem`     | Set readOnlyRootFilesystem in "copy-config" init-containers' Security Context                                                                                                                                                                                                                                  | `true`                     |
| `defaultInitContainers.copyConfig.containerSecurityContext.privileged`                 | Set privileged in "copy-config" init-containers' Security Context                                                                                                                                                                                                                                              | `false`                    |
| `defaultInitContainers.copyConfig.containerSecurityContext.allowPrivilegeEscalation`   | Set allowPrivilegeEscalation in "copy-config" init-containers' Security Context                                                                                                                                                                                                                                | `false`                    |
| `defaultInitContainers.copyConfig.containerSecurityContext.capabilities.add`           | List of capabilities to be added in "copy-config" init-containers                                                                                                                                                                                                                                              | `[]`                       |
| `defaultInitContainers.copyConfig.containerSecurityContext.capabilities.drop`          | List of capabilities to be dropped in "copy-config" init-containers                                                                                                                                                                                                                                            | `["ALL"]`                  |
| `defaultInitContainers.copyConfig.containerSecurityContext.seccompProfile.type`        | Set seccomp profile in "copy-config" init-containers                                                                                                                                                                                                                                                           | `RuntimeDefault`           |
| `defaultInitContainers.copyConfig.resourcesPreset`                                     | Set NiFi "copy-config" init container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if defaultInitContainers.copyConfig.resources is set (defaultInitContainers.copyConfig.resources is recommended for production).           | `nano`                     |
| `defaultInitContainers.copyConfig.resources`                                           | Set NiFi "copy-config" init container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                                                                      | `{}`                       |
| `defaultInitContainers.renderConfig.enabled`                                           | Enable the "render-config" init container                                                                                                                                                                                                                                                                      | `true`                     |
| `defaultInitContainers.renderConfig.containerSecurityContext.enabled`                  | Enabled "prepare-config" init-containers' Security Context                                                                                                                                                                                                                                                     | `true`                     |
| `defaultInitContainers.renderConfig.containerSecurityContext.seLinuxOptions`           | Set SELinux options in "prepare-config" init-containers                                                                                                                                                                                                                                                        | `{}`                       |
| `defaultInitContainers.renderConfig.containerSecurityContext.runAsUser`                | Set runAsUser in "prepare-config" init-containers' Security Context                                                                                                                                                                                                                                            | `1001`                     |
| `defaultInitContainers.renderConfig.containerSecurityContext.runAsGroup`               | Set runAsUser in "prepare-config" init-containers' Security Context                                                                                                                                                                                                                                            | `1001`                     |
| `defaultInitContainers.renderConfig.containerSecurityContext.runAsNonRoot`             | Set runAsNonRoot in "prepare-config" init-containers' Security Context                                                                                                                                                                                                                                         | `true`                     |
| `defaultInitContainers.renderConfig.containerSecurityContext.readOnlyRootFilesystem`   | Set readOnlyRootFilesystem in "prepare-config" init-containers' Security Context                                                                                                                                                                                                                               | `true`                     |
| `defaultInitContainers.renderConfig.containerSecurityContext.privileged`               | Set privileged in "prepare-config" init-containers' Security Context                                                                                                                                                                                                                                           | `false`                    |
| `defaultInitContainers.renderConfig.containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation in "prepare-config" init-containers' Security Context                                                                                                                                                                                                                             | `false`                    |
| `defaultInitContainers.renderConfig.containerSecurityContext.capabilities.add`         | List of capabilities to be added in "prepare-config" init-containers                                                                                                                                                                                                                                           | `[]`                       |
| `defaultInitContainers.renderConfig.containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped in "prepare-config" init-containers                                                                                                                                                                                                                                         | `["ALL"]`                  |
| `defaultInitContainers.renderConfig.containerSecurityContext.seccompProfile.type`      | Set seccomp profile in "prepare-config" init-containers                                                                                                                                                                                                                                                        | `RuntimeDefault`           |
| `defaultInitContainers.renderConfig.resourcesPreset`                                   | Set Airflow "prepare-config" init container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if defaultInitContainers.renderConfig.resources is set (defaultInitContainers.renderConfig.resources is recommended for production). | `nano`                     |
| `defaultInitContainers.renderConfig.resources`                                         | Set Airflow "prepare-config" init container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                                                                | `{}`                       |
| `defaultInitContainers.setAuth.enabled`                                                | Enable the "set-auth" init container                                                                                                                                                                                                                                                                           | `true`                     |
| `defaultInitContainers.setAuth.containerSecurityContext.enabled`                       | Enabled "set-auth" init-containers' Security Context                                                                                                                                                                                                                                                           | `true`                     |
| `defaultInitContainers.setAuth.containerSecurityContext.seLinuxOptions`                | Set SELinux options in "set-auth" init-containers                                                                                                                                                                                                                                                              | `{}`                       |
| `defaultInitContainers.setAuth.containerSecurityContext.runAsUser`                     | Set runAsUser in "set-auth" init-containers' Security Context                                                                                                                                                                                                                                                  | `1001`                     |
| `defaultInitContainers.setAuth.containerSecurityContext.runAsGroup`                    | Set runAsUser in "set-auth" init-containers' Security Context                                                                                                                                                                                                                                                  | `1001`                     |
| `defaultInitContainers.setAuth.containerSecurityContext.runAsNonRoot`                  | Set runAsNonRoot in "set-auth" init-containers' Security Context                                                                                                                                                                                                                                               | `true`                     |
| `defaultInitContainers.setAuth.containerSecurityContext.readOnlyRootFilesystem`        | Set readOnlyRootFilesystem in "set-auth" init-containers' Security Context                                                                                                                                                                                                                                     | `true`                     |
| `defaultInitContainers.setAuth.containerSecurityContext.privileged`                    | Set privileged in "set-auth" init-containers' Security Context                                                                                                                                                                                                                                                 | `false`                    |
| `defaultInitContainers.setAuth.containerSecurityContext.allowPrivilegeEscalation`      | Set allowPrivilegeEscalation in "set-auth" init-containers' Security Context                                                                                                                                                                                                                                   | `false`                    |
| `defaultInitContainers.setAuth.containerSecurityContext.capabilities.add`              | List of capabilities to be added in "set-auth" init-containers                                                                                                                                                                                                                                                 | `[]`                       |
| `defaultInitContainers.setAuth.containerSecurityContext.capabilities.drop`             | List of capabilities to be dropped in "set-auth" init-containers                                                                                                                                                                                                                                               | `["ALL"]`                  |
| `defaultInitContainers.setAuth.containerSecurityContext.seccompProfile.type`           | Set seccomp profile in "set-auth" init-containers                                                                                                                                                                                                                                                              | `RuntimeDefault`           |
| `defaultInitContainers.setAuth.resourcesPreset`                                        | Set Airflow "set-auth" init container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if defaultInitContainers.setAuth.resources is set (defaultInitContainers.setAuth.resources is recommended for production).                 | `nano`                     |
| `defaultInitContainers.setAuth.resources`                                              | Set Airflow "set-auth" init container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                                                                      | `{}`                       |
| `defaultInitContainers.setAuth.fips.openssl`                                           | Configure OpenSSL FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                                                                                                             | `""`                       |
| `defaultInitContainers.setAuth.fips.java`                                              | Configure JAVA FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                                                                                                                | `relaxed`                  |
| `defaultInitContainers.importCA.enabled`                                               | Enable the "import-ca" init container                                                                                                                                                                                                                                                                          | `true`                     |
| `defaultInitContainers.importCA.kubeRootCAConfigmap`                                   | Name of the system ConfigMap containing the kube-apiserver CA                                                                                                                                                                                                                                                  | `kube-root-ca.crt`         |
| `defaultInitContainers.importCA.containerSecurityContext.enabled`                      | Enabled "import-ca" init-containers' Security Context                                                                                                                                                                                                                                                          | `true`                     |
| `defaultInitContainers.importCA.containerSecurityContext.seLinuxOptions`               | Set SELinux options in "import-ca" init-containers                                                                                                                                                                                                                                                             | `{}`                       |
| `defaultInitContainers.importCA.containerSecurityContext.runAsUser`                    | Set runAsUser in "import-ca" init-containers' Security Context                                                                                                                                                                                                                                                 | `1001`                     |
| `defaultInitContainers.importCA.containerSecurityContext.runAsGroup`                   | Set runAsUser in "import-ca" init-containers' Security Context                                                                                                                                                                                                                                                 | `1001`                     |
| `defaultInitContainers.importCA.containerSecurityContext.runAsNonRoot`                 | Set runAsNonRoot in "import-ca" init-containers' Security Context                                                                                                                                                                                                                                              | `true`                     |
| `defaultInitContainers.importCA.containerSecurityContext.readOnlyRootFilesystem`       | Set readOnlyRootFilesystem in "import-ca" init-containers' Security Context                                                                                                                                                                                                                                    | `true`                     |
| `defaultInitContainers.importCA.containerSecurityContext.privileged`                   | Set privileged in "import-ca" init-containers' Security Context                                                                                                                                                                                                                                                | `false`                    |
| `defaultInitContainers.importCA.containerSecurityContext.allowPrivilegeEscalation`     | Set allowPrivilegeEscalation in "import-ca" init-containers' Security Context                                                                                                                                                                                                                                  | `false`                    |
| `defaultInitContainers.importCA.containerSecurityContext.capabilities.add`             | List of capabilities to be added in "import-ca" init-containers                                                                                                                                                                                                                                                | `[]`                       |
| `defaultInitContainers.importCA.containerSecurityContext.capabilities.drop`            | List of capabilities to be dropped in "import-ca" init-containers                                                                                                                                                                                                                                              | `["ALL"]`                  |
| `defaultInitContainers.importCA.containerSecurityContext.seccompProfile.type`          | Set seccomp profile in "import-ca" init-containers                                                                                                                                                                                                                                                             | `RuntimeDefault`           |
| `defaultInitContainers.importCA.resourcesPreset`                                       | Set Airflow "import-ca" init container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if defaultInitContainers.importCA.resources is set (defaultInitContainers.importCA.resources is recommended for production).              | `nano`                     |
| `defaultInitContainers.importCA.resources`                                             | Set Airflow "import-ca" init container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                                                                     | `{}`                       |
| `defaultInitContainers.importCA.fips.openssl`                                          | Configure OpenSSL FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                                                                                                             | `""`                       |
| `defaultInitContainers.importCA.fips.java`                                             | Configure JAVA FIPS mode: '', 'restricted', 'relaxed', 'off'. If empty (""), 'global.defaultFips' would be used                                                                                                                                                                                                | `relaxed`                  |
| `defaultInitContainers.volumePermissions.enabled`                                      | Enable init container that changes the owner/group of the PV mount point to `runAsUser:fsGroup`                                                                                                                                                                                                                | `false`                    |
| `defaultInitContainers.volumePermissions.resourcesPreset`                              | Set init container resources according to one common preset (allowed values: none, nano, small, medium, large, xlarge, 2xlarge). This is ignored if volumePermissions.resources is set (volumePermissions.resources is recommended for production).                                                            | `nano`                     |
| `defaultInitContainers.volumePermissions.resources`                                    | Set init container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                                                                                                         | `{}`                       |
| `defaultInitContainers.volumePermissions.containerSecurityContext.enabled`             | Enabled init container' Security Context                                                                                                                                                                                                                                                                       | `true`                     |
| `defaultInitContainers.volumePermissions.containerSecurityContext.seLinuxOptions`      | Set SELinux options in init container                                                                                                                                                                                                                                                                          | `{}`                       |
| `defaultInitContainers.volumePermissions.containerSecurityContext.runAsUser`           | Set init container's Security Context runAsUser                                                                                                                                                                                                                                                                | `0`                        |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
helm install my-release \
  --set auth.username=myuser \
  --set auth.password=password123 \
    oci://REGISTRY_NAME/REPOSITORY_NAME/nifi
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamicharts`.

The above command sets the Apache NiFi native username as `myuser` with password `password123`.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm install my-release -f values.yaml oci://REGISTRY_NAME/REPOSITORY_NAME/nifi
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamicharts`.
> **Tip**: You can use the default [values.yaml](https://github.com/bitnami/charts/blob/main/template/CHART_NAME/values.yaml)

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

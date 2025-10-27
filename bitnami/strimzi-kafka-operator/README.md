<!--- app-name: Strimzi Kafka Operator -->

# Bitnami Secure Images Helm chart for Strimzi Kafka Operator

Strimzi Kafka Operator provides a way to run Apache Kafka clusters on Kubernetes with different deployment configurations.

[Overview of Strimzi Kafka Operator](https://strimzi.io)

Trademarks: This software listing is packaged by Bitnami. The respective trademarks mentioned in the offering are owned by the respective companies, and use of them does not imply any affiliation or endorsement.

## TL;DR

```console
helm install my-release oci://MY-OCI-REGISTRY/strimzi-kafka-operator
```

Looking to use Strimzi Kafka Operator in production? Try [VMware Tanzu Application Catalog](https://bitnami.com/enterprise), the commercial edition of the Bitnami catalog.

## Introduction

This chart bootstraps a Strimzi Kafka Operator deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.27+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://REGISTRY_NAME/REPOSITORY_NAME/strimzi-kafka-operator
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamichartsprem`.

The command deploys Strimzi Kafka Operator on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Configuration and installation details

### Deploying extra resources

Apart from the Strimzi Kafka Operator, you may want to deploy KafkaNodePool and Kafka objects. For covering this case, the chart allows adding the full specification of other objects using the `extraDeploy` parameter. The following example creates a Apache Kafka cluster with 3 broker and 3 controller nodes:

```yaml
extraDeploy:
- apiVersion: kafka.strimzi.io/v1beta2
  kind: KafkaNodePool
  metadata:
    name: controller
    labels:
      strimzi.io/cluster: my-cluster
  spec:
    replicas: 3
    roles:
      - controller
    storage:
      type: jbod
      volumes:
        - id: 0
          type: persistent-claim
          size: 5Gi
          kraftMetadata: shared
          deleteClaim: false
- apiVersion: kafka.strimzi.io/v1beta2
  kind: KafkaNodePool
  metadata:
    name: broker
    labels:
      strimzi.io/cluster: my-cluster
  spec:
    replicas: 3
    roles:
      - broker
    storage:
      type: jbod
      volumes:
        - id: 0
          type: persistent-claim
          size: 5Gi
          kraftMetadata: shared
          deleteClaim: false
- apiVersion: kafka.strimzi.io/v1beta2
  kind: Kafka
  metadata:
    name: my-cluster
    annotations:
      strimzi.io/node-pools: enabled
      strimzi.io/kraft: enabled
  spec:
    kafka:
      version: 4.0.0
      metadataVersion: 4.0-IV3
      listeners:
        - name: plain
          port: 9092
          type: internal
          tls: false
        - name: tls
          port: 9093
          type: internal
          tls: true
      config:
        offsets.topic.replication.factor: 1
        transaction.state.log.replication.factor: 1
        transaction.state.log.min.isr: 1
        default.replication.factor: 1
        min.insync.replicas: 1
```

Check the [official quickstart guide](https://strimzi.io/quickstarts/) for more examples of how to deploy Kafka resources.

### Prometheus metrics

This chart can be integrated with Prometheus by setting `metrics.enabled` to true. This will expose the Strimzi Kafka Operator metrics port in both the containers and services. The services will also have the necessary annotations to be automatically scraped by Prometheus.

#### Prometheus requirements

It is necessary to have a working installation of Prometheus or Prometheus Operator for the integration to work. Install the [Bitnami Prometheus helm chart](https://github.com/bitnami/charts/tree/main/bitnami/prometheus) or the [Bitnami Kube Prometheus helm chart](https://github.com/bitnami/charts/tree/main/bitnami/kube-prometheus) to easily have a working Prometheus in your cluster.

#### Integration with Prometheus Operator

The chart can deploy `ServiceMonitor` objects for integration with Prometheus Operator installations. To do so, set the value `metrics.serviceMonitor.enabled=true`. Ensure that the Prometheus Operator `CustomResourceDefinitions` are installed in the cluster or it will fail with the following error:

```text
no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
```

Install the [Bitnami Kube Prometheus helm chart](https://github.com/bitnami/charts/tree/main/bitnami/kube-prometheus) for having the necessary CRDs and the Prometheus Operator.

### [Rolling VS Immutable tags](https://docs.vmware.com/en/VMware-Tanzu-Application-Catalog/services/tutorials/GUID-understand-rolling-tags-containers-index.html)

It is strongly recommended to use immutable tags in a production environment. This ensures your deployment does not change automatically if the same tag is updated with a different image.

Bitnami will release a new chart updating its containers if a new version of the main container, significant changes, or critical vulnerabilities exist.

### Additional environment variables

In case you want to add extra environment variables (useful for advanced operations like custom init scripts), you can use the `extraEnvVars` property.

```yaml
extraEnvVars:
  - name: LOG_LEVEL
    value: error
```

Alternatively, you can use a ConfigMap or a Secret with the environment variables. To do so, use the `extraEnvVarsCM` or the `extraEnvVarsSecret` values.

### Sidecars

If additional containers are needed in the same pod as Strimzi Kafka Operator (such as additional metrics or logging exporters), they can be defined using the `sidecars` parameter.

```yaml
sidecars:
- name: your-image-name
  image: your-image
  imagePullPolicy: Always
  ports:
  - name: portname
    containerPort: 1234
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

## Parameters

### Global parameters

| Name                                                  | Description                                                                                                                                                                                                                                                                                                                                                         | Value   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `global.imageRegistry`                                | Global Docker Image registry                                                                                                                                                                                                                                                                                                                                        | `""`    |
| `global.imagePullSecrets`                             | Global Docker registry secret names as an array                                                                                                                                                                                                                                                                                                                     | `[]`    |
| `global.defaultStorageClass`                          | Global default StorageClass for Persistent Volume(s)                                                                                                                                                                                                                                                                                                                | `""`    |
| `global.security.allowInsecureImages`                 | Allows skipping image verification                                                                                                                                                                                                                                                                                                                                  | `false` |
| `global.compatibility.openshift.adaptSecurityContext` | Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC: remove runAsUser, runAsGroup and fsGroup and let the platform use their allowed default IDs. Possible values: auto (apply if the detected running cluster is Openshift), force (perform the adaptation always), disabled (do not perform adaptation) | `auto`  |
| `global.compatibility.omitEmptySeLinuxOptions`        | If set to true, removes the seLinuxOptions from the securityContexts when it is set to an empty object                                                                                                                                                                                                                                                              | `false` |

### Common parameters

| Name                | Description                                                | Value           |
| ------------------- | ---------------------------------------------------------- | --------------- |
| `kubeVersion`       | Override Kubernetes version reported by .Capabilities      | `""`            |
| `apiVersions`       | Override Kubernetes API versions reported by .Capabilities | `[]`            |
| `nameOverride`      | String to partially override common.names.name             | `""`            |
| `fullnameOverride`  | String to fully override common.names.fullname             | `""`            |
| `namespaceOverride` | String to fully override common.names.namespace            | `""`            |
| `commonLabels`      | Labels to add to all deployed objects                      | `{}`            |
| `commonAnnotations` | Annotations to add to all deployed objects                 | `{}`            |
| `clusterDomain`     | Kubernetes cluster domain name                             | `cluster.local` |
| `extraDeploy`       | Array of extra objects to deploy with the release          | `[]`            |

### Images Parameters

| Name                            | Description                                                                                                                                                       | Value                                    |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `image.registry`                | Strimzi Kafka Operator image registry                                                                                                                             | `REGISTRY_NAME`                          |
| `image.repository`              | Strimzi Kafka Operator image repository                                                                                                                           | `REPOSITORY_NAME/strimzi-kafka-operator` |
| `image.digest`                  | Strimzi Kafka Operator image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended) | `""`                                     |
| `image.pullPolicy`              | Strimzi Kafka Operator image pull policy                                                                                                                          | `IfNotPresent`                           |
| `image.pullSecrets`             | Strimzi Kafka Operator image pull secrets                                                                                                                         | `[]`                                     |
| `kafkaImages.4.0.0.registry`    | Strimzi Kafka 4.0.0 image registry                                                                                                                                | `REGISTRY_NAME`                          |
| `kafkaImages.4.0.0.repository`  | Strimzi Kafka 4.0.0 image repository                                                                                                                              | `REPOSITORY_NAME/strimzi-kafka`          |
| `kafkaImages.4.0.0.digest`      | Strimzi Kafka 4.0.0 image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended)    | `""`                                     |
| `kafkaImages.4.0.0.pullPolicy`  | Strimzi Kafka 4.0.0 image pull policy                                                                                                                             | `IfNotPresent`                           |
| `kafkaImages.4.0.0.pullSecrets` | Strimzi Kafka 4.0.0 image pull secrets                                                                                                                            | `[]`                                     |
| `kafkaImages.4.1.0.registry`    | Strimzi Kafka 4.1.0 image registry                                                                                                                                | `REGISTRY_NAME`                          |
| `kafkaImages.4.1.0.repository`  | Strimzi Kafka 4.1.0 image repository                                                                                                                              | `REPOSITORY_NAME/strimzi-kafka`          |
| `kafkaImages.4.1.0.digest`      | Strimzi Kafka 4.1.0 image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended)    | `""`                                     |
| `kafkaImages.4.1.0.pullPolicy`  | Strimzi Kafka 4.1.0 image pull policy                                                                                                                             | `IfNotPresent`                           |
| `kafkaImages.4.1.0.pullSecrets` | Strimzi Kafka 4.1.0 image pull secrets                                                                                                                            | `[]`                                     |
| `kafkaBridgeImage.registry`     | Kafka Bridge image registry                                                                                                                                       | `REGISTRY_NAME`                          |
| `kafkaBridgeImage.repository`   | Kafka Bridge image repository                                                                                                                                     | `REPOSITORY_NAME/kafka`                  |
| `kafkaBridgeImage.digest`       | Kafka Bridge image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended)           | `""`                                     |
| `kafkaBridgeImage.pullPolicy`   | Kafka Bridge image pull policy                                                                                                                                    | `IfNotPresent`                           |
| `kafkaBridgeImage.pullSecrets`  | Kafka Bridge image pull secrets                                                                                                                                   | `[]`                                     |
| `kanikoImage.registry`          | Kaniko Executor image registry                                                                                                                                    | `REGISTRY_NAME`                          |
| `kanikoImage.repository`        | Kaniko Executor image repository                                                                                                                                  | `REPOSITORY_NAME/kaniko`                 |
| `kanikoImage.digest`            | Kaniko Executor image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag image tag (immutable tags are recommended)        | `""`                                     |
| `kanikoImage.pullPolicy`        | Kaniko Executor image pull policy                                                                                                                                 | `IfNotPresent`                           |
| `kanikoImage.pullSecrets`       | Kaniko Executor image pull secrets                                                                                                                                | `[]`                                     |

### Strimzi Kafka Operator Parameters

| Name                                                | Description                                                                                                                                                                                                                              | Value            |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `replicaCount`                                      | Number of Strimzi Kafka Operator replicas to deploy                                                                                                                                                                                      | `1`              |
| `containerPorts.http`                               | Strimzi Kafka Operator HTTP container port                                                                                                                                                                                               | `8080`           |
| `extraContainerPorts`                               | Optionally specify extra list of additional ports for Strimzi Kafka Operator containers                                                                                                                                                  | `[]`             |
| `resourcesPreset`                                   | Set Strimzi Kafka Operator container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if resources is set (resources is recommended for production). | `small`          |
| `resources`                                         | Set Strimzi Kafka Operator container requests and limits for different resources like CPU or memory (essential for production workloads)                                                                                                 | `{}`             |
| `podSecurityContext.enabled`                        | Enable Strimzi Kafka Operator pods' Security Context                                                                                                                                                                                     | `true`           |
| `podSecurityContext.fsGroupChangePolicy`            | Set filesystem group change policy for Strimzi Kafka Operator pods                                                                                                                                                                       | `Always`         |
| `podSecurityContext.sysctls`                        | Set kernel settings using the sysctl interface for Strimzi Kafka Operator pods                                                                                                                                                           | `[]`             |
| `podSecurityContext.supplementalGroups`             | Set filesystem extra groups for Strimzi Kafka Operator pods                                                                                                                                                                              | `[]`             |
| `podSecurityContext.fsGroup`                        | Set fsGroup in Strimzi Kafka Operator pods' Security Context                                                                                                                                                                             | `1001`           |
| `containerSecurityContext.enabled`                  | Enabled Strimzi Kafka Operator container' Security Context                                                                                                                                                                               | `true`           |
| `containerSecurityContext.seLinuxOptions`           | Set SELinux options in Strimzi Kafka Operator container                                                                                                                                                                                  | `{}`             |
| `containerSecurityContext.runAsUser`                | Set runAsUser in Strimzi Kafka Operator container' Security Context                                                                                                                                                                      | `1001`           |
| `containerSecurityContext.runAsGroup`               | Set runAsGroup in Strimzi Kafka Operator container' Security Context                                                                                                                                                                     | `1001`           |
| `containerSecurityContext.runAsNonRoot`             | Set runAsNonRoot in Strimzi Kafka Operator container' Security Context                                                                                                                                                                   | `true`           |
| `containerSecurityContext.readOnlyRootFilesystem`   | Set readOnlyRootFilesystem in Strimzi Kafka Operator container' Security Context                                                                                                                                                         | `true`           |
| `containerSecurityContext.privileged`               | Set privileged in Strimzi Kafka Operator container' Security Context                                                                                                                                                                     | `false`          |
| `containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation in Strimzi Kafka Operator container' Security Context                                                                                                                                                       | `false`          |
| `containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped in Strimzi Kafka Operator container                                                                                                                                                                   | `["ALL"]`        |
| `containerSecurityContext.seccompProfile.type`      | Set seccomp profile in Strimzi Kafka Operator container                                                                                                                                                                                  | `RuntimeDefault` |
| `livenessProbe.enabled`                             | Enable livenessProbe on Strimzi Kafka Operator containers                                                                                                                                                                                | `true`           |
| `livenessProbe.initialDelaySeconds`                 | Initial delay seconds for livenessProbe                                                                                                                                                                                                  | `10`             |
| `livenessProbe.periodSeconds`                       | Period seconds for livenessProbe                                                                                                                                                                                                         | `30`             |
| `livenessProbe.timeoutSeconds`                      | Timeout seconds for livenessProbe                                                                                                                                                                                                        | `1`              |
| `livenessProbe.failureThreshold`                    | Failure threshold for livenessProbe                                                                                                                                                                                                      | `3`              |
| `livenessProbe.successThreshold`                    | Success threshold for livenessProbe                                                                                                                                                                                                      | `1`              |
| `readinessProbe.enabled`                            | Enable readinessProbe on Strimzi Kafka Operator containers                                                                                                                                                                               | `true`           |
| `readinessProbe.initialDelaySeconds`                | Initial delay seconds for readinessProbe                                                                                                                                                                                                 | `10`             |
| `readinessProbe.periodSeconds`                      | Period seconds for readinessProbe                                                                                                                                                                                                        | `30`             |
| `readinessProbe.timeoutSeconds`                     | Timeout seconds for readinessProbe                                                                                                                                                                                                       | `1`              |
| `readinessProbe.failureThreshold`                   | Failure threshold for readinessProbe                                                                                                                                                                                                     | `3`              |
| `readinessProbe.successThreshold`                   | Success threshold for readinessProbe                                                                                                                                                                                                     | `1`              |
| `startupProbe.enabled`                              | Enable startupProbe on Strimzi Kafka Operator containers                                                                                                                                                                                 | `false`          |
| `startupProbe.initialDelaySeconds`                  | Initial delay seconds for startupProbe                                                                                                                                                                                                   | `10`             |
| `startupProbe.periodSeconds`                        | Period seconds for startupProbe                                                                                                                                                                                                          | `15`             |
| `startupProbe.timeoutSeconds`                       | Timeout seconds for startupProbe                                                                                                                                                                                                         | `5`              |
| `startupProbe.failureThreshold`                     | Failure threshold for startupProbe                                                                                                                                                                                                       | `10`             |
| `startupProbe.successThreshold`                     | Success threshold for startupProbe                                                                                                                                                                                                       | `1`              |
| `customLivenessProbe`                               | Custom livenessProbe that overrides the default one                                                                                                                                                                                      | `{}`             |
| `customReadinessProbe`                              | Custom readinessProbe that overrides the default one                                                                                                                                                                                     | `{}`             |
| `customStartupProbe`                                | Custom startupProbe that overrides the default one                                                                                                                                                                                       | `{}`             |
| `watchAllNamespaces`                                | Watch for Strimzi Kafka Operator resources in all namespaces                                                                                                                                                                             | `false`          |
| `watchNamespaces`                                   | Watch for Strimzi Kafka Operator resources in the given namespaces                                                                                                                                                                       | `[]`             |
| `logLevel`                                          | Log level for Strimzi Kafka Operator                                                                                                                                                                                                     | `INFO`           |
| `logConfiguration`                                  | Custom log4j2 configuration for Strimzi Kafka Operator (auto-generated based on other parameters otherwise)                                                                                                                              | `""`             |
| `overrideLogConfiguration`                          | Log4j2 configuration configuration override. Values defined here takes precedence over the ones defined at `logConfiguration`                                                                                                            | `{}`             |
| `existingLogConfigmap`                              | The name of an existing ConfigMap with your custom log4j2 configuration                                                                                                                                                                  | `""`             |
| `enableLeaderElection`                              | Enable leader election for Strimzi Kafka Operator                                                                                                                                                                                        | `true`           |
| `fullReconciliationIntervalMs`                      | Full reconciliation interval in milliseconds                                                                                                                                                                                             | `120000`         |
| `operationTimeoutMs`                                | Operation timeout in milliseconds                                                                                                                                                                                                        | `300000`         |
| `connectBuildTimeoutMs`                             | Connect build timeout in milliseconds                                                                                                                                                                                                    | `300000`         |
| `featureGates`                                      | List of feature gates to enable/disable                                                                                                                                                                                                  | `[]`             |
| `command`                                           | Override default Strimzi Kafka Operator container command (useful when using custom images)                                                                                                                                              | `[]`             |
| `args`                                              | Override default Strimzi Kafka Operator container args (useful when using custom images)                                                                                                                                                 | `[]`             |
| `automountServiceAccountToken`                      | Mount Service Account token in Strimzi Kafka Operator pods                                                                                                                                                                               | `true`           |
| `hostAliases`                                       | Strimzi Kafka Operator pods host aliases                                                                                                                                                                                                 | `[]`             |
| `deploymentAnnotations`                             | Annotations for Strimzi Kafka Operator deployment                                                                                                                                                                                        | `{}`             |
| `podLabels`                                         | Extra labels for Strimzi Kafka Operator pods                                                                                                                                                                                             | `{}`             |
| `podAnnotations`                                    | Annotations for Strimzi Kafka Operator pods                                                                                                                                                                                              | `{}`             |
| `podAffinityPreset`                                 | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                      | `""`             |
| `podAntiAffinityPreset`                             | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                 | `soft`           |
| `nodeAffinityPreset.type`                           | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                                                                                                                | `""`             |
| `nodeAffinityPreset.key`                            | Node label key to match. Ignored if `affinity` is set                                                                                                                                                                                    | `""`             |
| `nodeAffinityPreset.values`                         | Node label values to match. Ignored if `affinity` is set                                                                                                                                                                                 | `[]`             |
| `affinity`                                          | Affinity for Strimzi Kafka Operator pods assignment                                                                                                                                                                                      | `{}`             |
| `nodeSelector`                                      | Node labels for Strimzi Kafka Operator pods assignment                                                                                                                                                                                   | `{}`             |
| `tolerations`                                       | Tolerations for Strimzi Kafka Operator pods assignment                                                                                                                                                                                   | `[]`             |
| `updateStrategy.type`                               | Strimzi Kafka Operator deployment strategy type                                                                                                                                                                                          | `RollingUpdate`  |
| `priorityClassName`                                 | Strimzi Kafka Operator pods' priorityClassName                                                                                                                                                                                           | `""`             |
| `topologySpreadConstraints`                         | Topology Spread Constraints for Strimzi Kafka Operator pod assignment spread across your cluster among failure-domains                                                                                                                   | `[]`             |
| `schedulerName`                                     | Name of the k8s scheduler (other than default) for Strimzi Kafka Operator pods                                                                                                                                                           | `""`             |
| `terminationGracePeriodSeconds`                     | Seconds Strimzi Kafka Operator pods need to terminate gracefully                                                                                                                                                                         | `""`             |
| `lifecycleHooks`                                    | for Strimzi Kafka Operator containers to automate configuration before or after startup                                                                                                                                                  | `{}`             |
| `extraEnvVars`                                      | Array with extra environment variables to add to Strimzi Kafka Operator containers                                                                                                                                                       | `[]`             |
| `extraEnvVarsCM`                                    | Name of existing ConfigMap containing extra env vars for Strimzi Kafka Operator containers                                                                                                                                               | `""`             |
| `extraEnvVarsSecret`                                | Name of existing Secret containing extra env vars for Strimzi Kafka Operator containers                                                                                                                                                  | `""`             |
| `extraVolumes`                                      | Optionally specify extra list of additional volumes for the Strimzi Kafka Operator pods                                                                                                                                                  | `[]`             |
| `extraVolumeMounts`                                 | Optionally specify extra list of additional volumeMounts for the Strimzi Kafka Operator containers                                                                                                                                       | `[]`             |
| `sidecars`                                          | Add additional sidecar containers to the Strimzi Kafka Operator pods                                                                                                                                                                     | `[]`             |
| `initContainers`                                    | Add additional init containers to the Strimzi Kafka Operator pods                                                                                                                                                                        | `[]`             |
| `pdb.create`                                        | Enable/disable a Pod Disruption Budget creation                                                                                                                                                                                          | `true`           |
| `pdb.minAvailable`                                  | Minimum number/percentage of pods that should remain scheduled                                                                                                                                                                           | `""`             |
| `pdb.maxUnavailable`                                | Maximum number/percentage of pods that may be made unavailable. Defaults to `1` if both `pdb.minAvailable` and `pdb.maxUnavailable` are empty.                                                                                           | `""`             |
| `autoscaling.vpa.enabled`                           | Enable VPA for Strimzi Kafka Operator pods                                                                                                                                                                                               | `false`          |
| `autoscaling.vpa.annotations`                       | Annotations for VPA resource                                                                                                                                                                                                             | `{}`             |
| `autoscaling.vpa.controlledResources`               | VPA List of resources that the vertical pod autoscaler can control. Defaults to cpu and memory                                                                                                                                           | `[]`             |
| `autoscaling.vpa.maxAllowed`                        | VPA Max allowed resources for the pod                                                                                                                                                                                                    | `{}`             |
| `autoscaling.vpa.minAllowed`                        | VPA Min allowed resources for the pod                                                                                                                                                                                                    | `{}`             |
| `autoscaling.vpa.updatePolicy.updateMode`           | Autoscaling update policy                                                                                                                                                                                                                | `Auto`           |
| `autoscaling.hpa.enabled`                           | Enable HPA for Strimzi Kafka Operator pods                                                                                                                                                                                               | `false`          |
| `autoscaling.hpa.minReplicas`                       | Minimum number of replicas                                                                                                                                                                                                               | `1`              |
| `autoscaling.hpa.maxReplicas`                       | Maximum number of replicas                                                                                                                                                                                                               | `3`              |
| `autoscaling.hpa.targetCPU`                         | Target CPU utilization percentage                                                                                                                                                                                                        | `75`             |
| `autoscaling.hpa.targetMemory`                      | Target Memory utilization percentage                                                                                                                                                                                                     | `""`             |

### Traffic Exposure Parameters

| Name                                    | Description                                                                                                   | Value  |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------ |
| `networkPolicy.enabled`                 | Specifies whether a NetworkPolicy should be created                                                           | `true` |
| `networkPolicy.kubeAPIServerPorts`      | List of possible endpoints to kube-apiserver (limit to your cluster settings to increase security)            | `[]`   |
| `networkPolicy.allowExternal`           | Don't require server label for connections                                                                    | `true` |
| `networkPolicy.allowExternalEgress`     | Allow the pod to access any range of port and all destinations.                                               | `true` |
| `networkPolicy.addExternalClientAccess` | Allow access from pods with client label set to "true". Ignored if `networkPolicy.allowExternal` is true.     | `true` |
| `networkPolicy.extraIngress`            | Add extra ingress rules to the NetworkPolicy                                                                  | `[]`   |
| `networkPolicy.extraEgress`             | Add extra ingress rules to the NetworkPolicy (ignored if allowExternalEgress=true)                            | `[]`   |
| `networkPolicy.ingressPodMatchLabels`   | Labels to match to allow traffic from other pods. Ignored if `networkPolicy.allowExternal` is true.           | `{}`   |
| `networkPolicy.ingressNSMatchLabels`    | Labels to match to allow traffic from other namespaces. Ignored if `networkPolicy.allowExternal` is true.     | `{}`   |
| `networkPolicy.ingressNSPodMatchLabels` | Pod labels to match to allow traffic from other namespaces. Ignored if `networkPolicy.allowExternal` is true. | `{}`   |

### Other Parameters

| Name                                          | Description                                                                                            | Value   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------- |
| `rbac.create`                                 | Specifies whether RBAC resources should be created                                                     | `true`  |
| `rbac.operator.rules`                         | Custom RBAC rules to set for "operator" ClusterRole                                                    | `[]`    |
| `rbac.global.rules`                           | Custom RBAC rules to set for "operator-global" ClusterRole                                             | `[]`    |
| `rbac.watched.rules`                          | Custom RBAC rules to set for "operator-watched" ClusterRole                                            | `[]`    |
| `rbac.leaderElection.rules`                   | Custom RBAC rules to set for "leader-election" ClusterRole                                             | `[]`    |
| `rbac.entityOperator.rules`                   | Custom RBAC rules to set for "entity-operator" ClusterRole                                             | `[]`    |
| `rbac.kafkaBroker.rules`                      | Custom RBAC rules to set for "kafka-broker" ClusterRole                                                | `[]`    |
| `rbac.kafkaClient.rules`                      | Custom RBAC rules to set for "kafka-client" ClusterRole                                                | `[]`    |
| `rbac.admin.rules`                            | Custom RBAC rules to set for "admin" ClusterRole                                                       | `[]`    |
| `rbac.view.rules`                             | Custom RBAC rules to set for "view" Cluster                                                            | `[]`    |
| `serviceAccount.create`                       | Specifies whether a ServiceAccount should be created                                                   | `true`  |
| `serviceAccount.name`                         | The name of the ServiceAccount to use.                                                                 | `""`    |
| `serviceAccount.annotations`                  | Additional Service Account annotations (evaluated as a template)                                       | `{}`    |
| `serviceAccount.automountServiceAccountToken` | Automount service account token for the server service account                                         | `true`  |
| `metrics.enabled`                             | Enable the export of Prometheus metrics                                                                | `false` |
| `metrics.service.port`                        | Strimzi Kafka Operator metrics service port                                                            | `8080`  |
| `metrics.service.extraPorts`                  | Extra ports to expose in Strimzi Kafka Operator metrics service                                        | `[]`    |
| `metrics.service.annotations`                 | Annotations for the Strimzi Kafka Operator metrics service                                             | `{}`    |
| `metrics.serviceMonitor.enabled`              | if `true`, creates a Prometheus Operator ServiceMonitor (also requires `metrics.enabled` to be `true`) | `false` |
| `metrics.serviceMonitor.namespace`            | Namespace in which Prometheus is running                                                               | `""`    |
| `metrics.serviceMonitor.annotations`          | Additional custom annotations for the ServiceMonitor                                                   | `{}`    |
| `metrics.serviceMonitor.labels`               | Extra labels for the ServiceMonitor                                                                    | `{}`    |
| `metrics.serviceMonitor.jobLabel`             | The name of the label on the target service to use as the job name in Prometheus                       | `""`    |
| `metrics.serviceMonitor.honorLabels`          | honorLabels chooses the metric's labels on collisions with target labels                               | `false` |
| `metrics.serviceMonitor.tlsConfig`            | TLS configuration used for scrape endpoints used by Prometheus                                         | `{}`    |
| `metrics.serviceMonitor.interval`             | Interval at which metrics should be scraped.                                                           | `""`    |
| `metrics.serviceMonitor.scrapeTimeout`        | Timeout after which the scrape is ended                                                                | `""`    |
| `metrics.serviceMonitor.metricRelabelings`    | Specify additional relabeling of metrics                                                               | `[]`    |
| `metrics.serviceMonitor.relabelings`          | Specify general relabeling                                                                             | `[]`    |
| `metrics.serviceMonitor.selector`             | Prometheus instance selector labels                                                                    | `{}`    |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
helm install my-release \
  --set logLevel=INFO \
    oci://REGISTRY_NAME/REPOSITORY_NAME/strimzi-kafka-operator
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamichartsprem`.

The above command sets the Strimzi Kafka Operator log level to `INFO`.

> NOTE: Once this chart is deployed, it is not possible to change the application's access credentials, such as usernames or passwords, using Helm. To change these application credentials after deployment, delete any persistent volumes (PVs) used by the chart and re-deploy it, or use the application's built-in administrative tools if available.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm install my-release -f values.yaml oci://REGISTRY_NAME/REPOSITORY_NAME/strimzi-kafka-operator
```

> Note: You need to substitute the placeholders `REGISTRY_NAME` and `REPOSITORY_NAME` with a reference to your Helm chart registry and repository. For example, in the case of Bitnami, you need to use `REGISTRY_NAME=registry-1.docker.io` and `REPOSITORY_NAME=bitnamichartsprem`.
> **Tip**: You can use the default [values.yaml](https://github.com/bitnami/charts-private/blob/main/bitnami/strimzi-kafka-operator/values.yaml)

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

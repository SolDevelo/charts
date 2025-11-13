<p align="center">
    <img width="180px" src="https://soldevelo.com/wp-content/uploads/2023/04/cropped-Frame-180x37.png" alt="SolDevelo Kafka" />
</p>

# SolDevelo Kafka Helm Chart

This repository is a **fork of Bitnami's Charts Library**. Currently, we maintain only the **Apache Kafka Helm chart**, but in the future we may add more charts. The Kafka chart is maintained by SolDevelo to provide up-to-date Kafka versions and fixes, while keeping the original Bitnami base.

## Features

- Maintained Kafka Helm chart by SolDevelo.
- Based on Bitnami Kafka chart (Apache-2.0 licensed).
- Ready to use with Kubernetes and Helm.
- Future support for additional charts planned.

## Get the chart

The recommended way to get the Kafka chart is to use Helm.

```console
helm install my-release oci://registry-1.docker.io/soldevelo/kafka-chart
```

To use a specific version, you can specify the chart version.

```console
helm install my-release oci://registry-1.docker.io/soldevelo/kafka-chart --version [VERSION]
```

If you wish, you can also clone the repository and install the chart locally.

```console
git clone https://github.com/soldevelo/charts.git
cd charts/soldevelo/kafka
helm install my-kafka .
```

> [!TIP]
> Remember to replace the `VERSION` placeholder in the example command above with the correct value.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+

## Run the application using Helm

The main folder contains the Kafka Helm chart. Deploy it using:

```console
helm install my-release oci://registry-1.docker.io/soldevelo/kafka-chart
```

## Contributing

We'd love for you to contribute to this Kafka Helm chart. You can request new features by creating an [issue](https://github.com/soldevelo/charts/issues/new/choose), or submit a [pull request](https://github.com/soldevelo/charts/pulls) with your contribution.

## License

Copyright 2025 SolDevelo
Based on Bitnami Charts (https://github.com/bitnami/charts) © 2025 Broadcom Inc. (licensed under Apache-2.0)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 <http://www.apache.org/licenses/LICENSE-2.0>
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

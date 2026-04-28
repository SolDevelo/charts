<p align="center">
    <img width="180px" src="https://soldevelo.com/wp-content/uploads/2023/04/cropped-Frame-180x37.png" alt="SolDevelo Kafka" />
</p>

# SolDevelo Helm Charts

This repository is a fork of Bitnami Charts, maintained by SolDevelo.
We provide selected charts with SolDevelo-maintained container images and ongoing updates.

## Features

- Forked from Bitnami Charts (Apache-2.0 licensed).
- Maintained by SolDevelo.
- Includes multiple production-ready Helm charts.
- Ready to use with Kubernetes and Helm.

## Available charts

- Kafka: `oci://registry-1.docker.io/soldevelo/kafka-chart`
- PostgreSQL HA: `oci://registry-1.docker.io/soldevelo/postgresql-ha-chart`

## Get the chart

Install one of the charts directly from OCI registry:

```console
helm install my-kafka oci://registry-1.docker.io/soldevelo/kafka-chart
helm install my-postgresql-ha oci://registry-1.docker.io/soldevelo/postgresql-ha-chart
```

To use a specific version, you can specify the chart version.

```console
helm install my-release oci://registry-1.docker.io/soldevelo/kafka-chart --version [VERSION]
helm install my-release oci://registry-1.docker.io/soldevelo/postgresql-ha-chart --version [VERSION]
```

If you wish, you can also clone the repository and install the chart locally.

```console
git clone https://github.com/soldevelo/charts.git
cd charts/soldevelo/kafka
helm install my-kafka .

cd ../postgresql-ha
helm install my-postgresql-ha .
```

> [!TIP]
> Remember to replace the `VERSION` placeholder in the example command above with the correct value.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+

## Contributing

We'd love your contributions. You can request new features by creating an [issue](https://github.com/soldevelo/charts/issues/new/choose), or submit a [pull request](https://github.com/soldevelo/charts/pulls).

## License

Copyright 2026 SolDevelo
Based on Bitnami Charts (https://github.com/bitnami/charts) © 2026 Broadcom Inc. (licensed under Apache-2.0)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 <http://www.apache.org/licenses/LICENSE-2.0>
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

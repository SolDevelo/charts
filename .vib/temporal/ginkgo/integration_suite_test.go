// Copyright Broadcom, Inc. All Rights Reserved.
// SPDX-License-Identifier: APACHE-2.0

package integration

import (
	"context"
	"flag"
	"fmt"
	"os"
	"testing"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	batchv1 "k8s.io/api/batch/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	bv1 "k8s.io/client-go/kubernetes/typed/batch/v1"
	cv1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"

	// For client auth plugins
	_ "k8s.io/client-go/plugin/pkg/client/auth"
)

const (
	APP_NAME         = "Temporal"
	POLLING_INTERVAL = 1 * time.Second
)

var (
	kubeconfig        = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	namespace         = flag.String("namespace", "", "namespace where the resources are deployed")
	releaseName       = flag.String("release-name", "", "name of the Temporal chart release")
	temporalPort      = flag.String("service-port", "7233", "port of the Temporal service")
	temporalNamespace = flag.String("temporal-namespace", "default", "Temporal namespace")
	timeoutSeconds    = flag.Int("timeout", 120, "timeout in seconds")
	timeout           time.Duration
)

func init() {
	timeout = time.Duration(*timeoutSeconds) * time.Second
}

func clusterConfigOrDie() *rest.Config {
	var config *rest.Config
	var err error

	if *kubeconfig != "" {
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)
	} else {
		config, err = rest.InClusterConfig()
	}
	if err != nil {
		panic(err.Error())
	}

	return config
}

func createClientConfigMap(ctx context.Context, c cv1.CoreV1Interface) error {
	mainGoContent, _ := os.ReadFile("./client/main.go")
	goModContent, _ := os.ReadFile("./client/go.mod")
	goSumContent, _ := os.ReadFile("./client/go.sum")

	_, err := c.ConfigMaps(*namespace).Create(ctx, &v1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name: fmt.Sprintf("%s-client-code", *releaseName),
		},
		Data: map[string]string{
			"main.go": string(mainGoContent),
			"go.mod":  string(goModContent),
			"go.sum":  string(goSumContent),
		},
	}, metav1.CreateOptions{})

	return err
}

func createClientJob(ctx context.Context, c bv1.BatchV1Interface, runAsUser *int64) error {
	// Provided pull secrets
	pullSecrets := []v1.LocalObjectReference{
		{Name: "cp-pullsecret-0"},
		{Name: "cp-pullsecret-1"},
		{Name: "cp-pullsecret-2"},
		{Name: "cp-pullsecret-3"},
		{Name: "tac-creds"},
	}

	securityContext := &v1.SecurityContext{
		Privileged:               &[]bool{false}[0],
		AllowPrivilegeEscalation: &[]bool{false}[0],
		RunAsNonRoot:             &[]bool{true}[0],
		RunAsUser:                runAsUser,
		Capabilities: &v1.Capabilities{
			Drop: []v1.Capability{"ALL"},
		},
		SeccompProfile: &v1.SeccompProfile{
			Type: "RuntimeDefault",
		},
	}

	job := &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name: fmt.Sprintf("%s-client", *releaseName),
		},
		TypeMeta: metav1.TypeMeta{
			Kind: "Job",
		},
		Spec: batchv1.JobSpec{
			Template: v1.PodTemplateSpec{
				Spec: v1.PodSpec{
					RestartPolicy:    "Never",
					ImagePullSecrets: pullSecrets,
					Containers: []v1.Container{
						{
							Name:       "go",
							Image:      "registry.app-catalog.vmware.com/eam/prd/containers/verified/common/minideb-bookworm/golang:latest",
							WorkingDir: "/app",
							Command:    []string{"go"},
							Args: []string{
								"run", "main.go",
							},
							Env: []v1.EnvVar{
								{
									Name:  "TEMPORAL_NAMESPACE",
									Value: *temporalNamespace,
								},
								{
									Name: "TEMPORAL_ADDRESS",
									Value: fmt.Sprintf("%s-frontend.%s.svc.cluster.local:%s",
										*releaseName, *namespace, *temporalPort),
								},
							},
							SecurityContext: securityContext,
							VolumeMounts: []v1.VolumeMount{
								{
									Name:      "client-code",
									MountPath: "/app",
								},
							},
						},
					},
					Volumes: []v1.Volume{
						{
							Name: "client-code",
							VolumeSource: v1.VolumeSource{
								ConfigMap: &v1.ConfigMapVolumeSource{
									LocalObjectReference: v1.LocalObjectReference{
										Name: fmt.Sprintf("%s-client-code", *releaseName),
									},
								},
							},
						},
					},
				},
			},
		},
	}

	_, err := c.Jobs(*namespace).Create(ctx, job, metav1.CreateOptions{})

	return err
}

func CheckRequirements() {
	if *namespace == "" {
		panic(fmt.Sprintf("The namespace where %s is deployed must be provided. Use the '--namespace' flag", APP_NAME))
	}
}

func TestIntegration(t *testing.T) {
	RegisterFailHandler(Fail)
	CheckRequirements()
	RunSpecs(t, fmt.Sprintf("%s Integration Tests", APP_NAME))
}

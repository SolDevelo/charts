package nats_test

import (
	"context"
	"flag"
	"fmt"
	"testing"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	batchv1 "k8s.io/api/batch/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

var (
	kubeconfig     string
	releaseName    string
	namespace      string
	username       string
	password       string
	timeoutSeconds int
	timeout        time.Duration
)

func init() {
	flag.StringVar(&kubeconfig, "kubeconfig", "", "absolute path to the kubeconfig file")
	flag.StringVar(&releaseName, "name", "", "name of the chart release")
	flag.StringVar(&namespace, "namespace", "", "namespace where the application is running")
	flag.StringVar(&username, "username", "", "nats user")
	flag.StringVar(&password, "password", "", "password for nats user")
	flag.IntVar(&timeoutSeconds, "timeout", 300, "timeout in seconds")
	timeout = time.Duration(timeoutSeconds) * time.Second
}

func TestNATS(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "NATS Persistence Test Suite")
}

func createJob(ctx context.Context, c kubernetes.Interface, name string, port string, args ...string) error {
	// Provided pull secrets
	pullSecrets := []v1.LocalObjectReference{
		{Name: "cp-pullsecret-0"},
		{Name: "cp-pullsecret-1"},
		{Name: "cp-pullsecret-2"},
		{Name: "cp-pullsecret-3"},
	}

	securityContext := &v1.SecurityContext{
		Privileged:               &[]bool{false}[0],
		AllowPrivilegeEscalation: &[]bool{false}[0],
		RunAsNonRoot:             &[]bool{true}[0],
		Capabilities: &v1.Capabilities{
			Drop: []v1.Capability{"ALL"},
		},
		SeccompProfile: &v1.SeccompProfile{
			Type: "RuntimeDefault",
		},
	}
	command := []string{"nats", "kv"}
	command = append(command, args[:]...)

	job := &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name: name,
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
							Name:    "nats",
							Image:   "registry.app-catalog.vmware.com/eam/prd/containers/verified/common/minideb-bookworm/natscli:latest",
							Command: command,
							Env: []v1.EnvVar{
								{
									Name:  "NATS_URL",
									Value: fmt.Sprintf("nats://%s:%s", releaseName, port),
								},
								{
									Name:  "NATS_USER",
									Value: username,
								},
								{
									Name:  "NATS_PASSWORD",
									Value: password,
								},
								{
									Name:  "NATS_CERT",
									Value: "/certs/tls.crt",
								},
								{
									Name:  "NATS_KEY",
									Value: "/certs/tls.key",
								},
								{
									Name:  "NATS_CA",
									Value: "/certs/ca.crt",
								},
							},
							SecurityContext: securityContext,
							VolumeMounts: []v1.VolumeMount{
								{
									Name:      "tls-certs",
									MountPath: "/certs",
								},
							},
						},
					},
					Volumes: []v1.Volume{
						{
							Name: "tls-certs",
							VolumeSource: v1.VolumeSource{
								Secret: &v1.SecretVolumeSource{
									SecretName: fmt.Sprintf("%s-client-crt", releaseName),
								},
							},
						},
					},
				},
			},
		},
	}

	_, err := c.BatchV1().Jobs(namespace).Create(ctx, job, metav1.CreateOptions{})

	return err
}

package solr_test

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
	stsName        string
	namespace      string
	username       string
	password       string
	timeoutSeconds int
	timeout        time.Duration
)

func init() {
	flag.StringVar(&kubeconfig, "kubeconfig", "", "absolute path to the kubeconfig file")
	flag.StringVar(&stsName, "name", "", "name of the primary statefulset")
	flag.StringVar(&namespace, "namespace", "", "namespace where the application is running")
	flag.StringVar(&username, "username", "", "database user")
	flag.StringVar(&password, "password", "", "database password for username")
	flag.IntVar(&timeoutSeconds, "timeout", 300, "timeout in seconds")
	timeout = time.Duration(timeoutSeconds) * time.Second
}

func TestSolr(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Solr Persistence Test Suite")
}

func createJob(ctx context.Context, c kubernetes.Interface, name string, port string, image string, args ...string) error {
	// Default job TTL in seconds
	ttl := int32(10)
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
	command := []string{"solr"}
	command = append(command, args[:]...)
	command = append(command, "--solr-url", fmt.Sprintf("https://%s:%s", stsName, port))

	job := &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name: name,
		},
		TypeMeta: metav1.TypeMeta{
			Kind: "Job",
		},
		Spec: batchv1.JobSpec{
			TTLSecondsAfterFinished: &ttl,
			Template: v1.PodTemplateSpec{
				Spec: v1.PodSpec{
					RestartPolicy: "Never",
					InitContainers: []v1.Container{
						{
							Name:    "init-certs",
							Image:   image,
							Command: []string{"/scripts/init-certs.sh"},
							Env: []v1.EnvVar{
								{
									Name:  "SOLR_SSL_KEY_STORE_PASSWORD_FILE",
									Value: "/opt/bitnami/solr/secrets/tls/keystore-password",
								},
								{
									Name:  "SOLR_SSL_TRUST_STORE_PASSWORD_FILE",
									Value: "/opt/bitnami/solr/secrets/tls/truststore-password",
								},
							},
							SecurityContext: securityContext,
							VolumeMounts: []v1.VolumeMount{{
								Name:      "certs",
								MountPath: "/certs",
							}, {
								Name:      "solr-scripts",
								MountPath: "/scripts/init-certs.sh",
								SubPath:   "init-certs.sh",
							}, {
								Name:      "solr-tls-secret",
								MountPath: "/opt/bitnami/solr/secrets/tls",
							}, {
								Name:      "empty-dir",
								MountPath: "/tmp",
								SubPath:   "tmp-dir",
							}, {
								Name:      "empty-dir",
								MountPath: "/opt/bitnami/solr/certs",
								SubPath:   "app-certs-dir",
							}},
						},
					},
					Containers: []v1.Container{
						{
							Name:    "solr",
							Image:   image,
							Command: command,
							Env: []v1.EnvVar{
								{
									Name:  "SOLR_AUTHENTICATION_OPTS",
									Value: fmt.Sprintf("-Dbasicauth=%s:%s", username, password),
								},
								{
									Name:  "SOLR_AUTH_TYPE",
									Value: "basic",
								},
								{
									Name:  "SOLR_SSL_ENABLED",
									Value: "true",
								},
								{
									Name: "SOLR_SSL_KEY_STORE_PASSWORD",
									ValueFrom: &v1.EnvVarSource{
										SecretKeyRef: &v1.SecretKeySelector{
											LocalObjectReference: v1.LocalObjectReference{
												Name: fmt.Sprintf("%s-tls-pass", stsName),
											},
											Key: "keystore-password",
										},
									},
								},
								{
									Name: "SOLR_SSL_TRUST_STORE_PASSWORD",
									ValueFrom: &v1.EnvVarSource{
										SecretKeyRef: &v1.SecretKeySelector{
											LocalObjectReference: v1.LocalObjectReference{
												Name: fmt.Sprintf("%s-tls-pass", stsName),
											},
											Key: "truststore-password",
										},
									},
								},
								{
									Name:  "SOLR_SSL_KEY_STORE",
									Value: "/opt/bitnami/solr/certs/keystore.p12",
								},
								{
									Name:  "SOLR_SSL_TRUST_STORE",
									Value: "/opt/bitnami/solr/certs/truststore.p12",
								},
							},
							SecurityContext: securityContext,
							VolumeMounts: []v1.VolumeMount{{
								Name:      "empty-dir",
								MountPath: "/tmp",
								SubPath:   "tmp-dir",
							}, {
								Name:      "empty-dir",
								MountPath: "/opt/bitnami/solr/certs",
								SubPath:   "app-certs-dir",
							}},
						},
					},
					Volumes: []v1.Volume{{
						Name: "empty-dir",
						VolumeSource: v1.VolumeSource{
							EmptyDir: &v1.EmptyDirVolumeSource{},
						},
					}, {
						Name: "certs",
						VolumeSource: v1.VolumeSource{
							Secret: &v1.SecretVolumeSource{
								SecretName: fmt.Sprintf("%s-crt", stsName),
							},
						},
					}, {
						Name: "solr-scripts",
						VolumeSource: v1.VolumeSource{
							ConfigMap: &v1.ConfigMapVolumeSource{
								LocalObjectReference: v1.LocalObjectReference{
									Name: fmt.Sprintf("%s-scripts", stsName),
								},
								DefaultMode: func(i int32) *int32 { return &i }(493),
							},
						},
					}, {
						Name: "solr-tls-secret",
						VolumeSource: v1.VolumeSource{
							Secret: &v1.SecretVolumeSource{
								SecretName: fmt.Sprintf("%s-tls-pass", stsName),
							},
						},
					}},
				},
			},
		},
	}

	_, err := c.BatchV1().Jobs(namespace).Create(ctx, job, metav1.CreateOptions{})

	return err
}

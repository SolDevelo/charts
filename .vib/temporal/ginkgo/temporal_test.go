// Copyright Broadcom, Inc. All Rights Reserved.
// SPDX-License-Identifier: APACHE-2.0

package integration

import (
	"context"
	"fmt"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	batchv1 "k8s.io/api/batch/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	av1 "k8s.io/client-go/kubernetes/typed/apps/v1"
	bv1 "k8s.io/client-go/kubernetes/typed/batch/v1"
	cv1 "k8s.io/client-go/kubernetes/typed/core/v1"

	// For client auth plugins
	_ "k8s.io/client-go/plugin/pkg/client/auth"
)

// This test ensures a Temporal Client can create a worker that executes a simple workflow
var _ = Describe("Temporal:", func() {
	var appsclient av1.AppsV1Interface
	var coreclient cv1.CoreV1Interface
	var batchclient bv1.BatchV1Interface
	var ctx context.Context

	BeforeEach(func() {
		appsclient = av1.NewForConfigOrDie(clusterConfigOrDie())
		batchclient = bv1.NewForConfigOrDie(clusterConfigOrDie())
		coreclient = cv1.NewForConfigOrDie(clusterConfigOrDie())
		ctx = context.Background()
	})

	When("Temporal is running", func() {
		Describe("a worker should be able to execute a simple workflow", func() {
			It("should create a client job to execute a workflow", func() {
				getSucceededJobs := func(j *batchv1.Job) int32 { return j.Status.Succeeded }

				By("checking Temporal Frontend is available")
				frontendDplName := fmt.Sprintf("%s-frontend", *releaseName)
				frontendDpl, err := appsclient.Deployments(*namespace).Get(ctx, frontendDplName, metav1.GetOptions{})
				Expect(err).NotTo(HaveOccurred())

				By("creating a ConfigMap with the client code")
				err = createClientConfigMap(ctx, coreclient)
				Expect(err).ToNot(HaveOccurred())

				By("creating a Job to execute a workflow")
				err = createClientJob(ctx, batchclient, frontendDpl.Spec.Template.Spec.Containers[0].SecurityContext.RunAsUser)
				Expect(err).ToNot(HaveOccurred())

				By("waiting for the Job to succeed")
				Eventually(func() (*batchv1.Job, error) {
					return batchclient.Jobs(*namespace).Get(ctx, fmt.Sprintf("%s-client", *releaseName), metav1.GetOptions{})
				}, timeout, POLLING_INTERVAL).Should(WithTransform(getSucceededJobs, Equal(int32(1))))

				By("deleting the Job once it has succeeded")
				err = batchclient.Jobs(*namespace).Delete(ctx, fmt.Sprintf("%s-client", *releaseName), metav1.DeleteOptions{})
				Expect(err).NotTo(HaveOccurred())

				By("deleting the ConfigMap once the Job has succeeded")
				err = coreclient.ConfigMaps(*namespace).Delete(ctx, fmt.Sprintf("%s-client-code", *releaseName), metav1.DeleteOptions{})
				Expect(err).NotTo(HaveOccurred())
			})
		})
	})
})

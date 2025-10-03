// Copyright Broadcom, Inc. All Rights Reserved.
// SPDX-License-Identifier: APACHE-2.0

package integration

import (

	// For client auth plugins

	"context"
	"fmt"
	"time"

	utils "github.com/bitnami/charts-private/.vib/common-tests/ginkgo-utils"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	cv1 "k8s.io/client-go/kubernetes/typed/core/v1"

	_ "k8s.io/client-go/plugin/pkg/client/auth"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

// This test ensures that the deployed ClusterPolicy correctly adds a K8S_IMAGE to a sample pod
var _ = Describe("kyverno:", func() {
	var coreclient cv1.CoreV1Interface
	var ctx context.Context

	BeforeEach(func() {
		coreclient = cv1.NewForConfigOrDie(clusterConfigOrDie())
		ctx = context.Background()
	})

	When("a testing pod is created", func() {
		var testingPod *v1.Pod

		BeforeEach(func() {
			// We need to make sure every Kyverno pods are running before launching the tests
			kyvernoPods := utils.GetPodsByLabelOrDie(ctx, coreclient, *namespace, "app.kubernetes.io/name=kyverno")
			for _, p := range kyvernoPods.Items {
				isPodRunning := false
				err := utils.Retry("IsPodRunning", 5, 5000, func() (bool, error) {
					res, err2 := utils.IsPodRunning(ctx, coreclient, *namespace, p.GetName())
					isPodRunning = res
					return res, err2
				})
				if err != nil {
					panic(err.Error())
				}
				Expect(isPodRunning).To(BeTrue())
			}

			testingPod = createTestingPodOrDie(ctx, coreclient)
			isPodRunning := false
			// We need to make sure the pod is out of the "ContainerCreating" phase
			// to avoid errors when checking its logs
			err := utils.Retry("IsPodRunning", 5, 5000, func() (bool, error) {
				res, err2 := utils.IsPodRunning(ctx, coreclient, *namespace, testingPod.GetName())
				isPodRunning = res
				return res, err2
			})
			if err != nil {
				panic(err.Error())
			}
			Expect(isPodRunning).To(BeTrue())
		})

		AfterEach(func() {
			// Not need to panic here if failed, the cluster is expected to clean up with the undeployment
			coreclient.Pods(*namespace).Delete(ctx, testingPod.GetName(), metav1.DeleteOptions{})
		})

		Describe("the logs show that", func() {
			var sampleLogs []string

			BeforeEach(func() {
				pattern := "Script finished correctly"
				patternFound := false
				err := utils.Retry("ContainerLogsContainPattern", 5, 5*time.Second, func() (bool, error) {
					res, err2 := utils.ContainerLogsContainPattern(ctx, coreclient, *namespace, testingPod.GetName(), "vib-sample", pattern)
					patternFound = res
					return res, err2
				})
				if err != nil {
					panic(err.Error())
				}
				cliPods := utils.GetPodsByLabelOrDie(ctx, coreclient, *namespace, "app=vib-sample")
				sampleLogs = utils.GetContainerLogsOrDie(ctx, coreclient, *namespace, cliPods.Items[0].GetName(), "vib-sample")

				// Debug code left as is, given configuration complexity
				if !patternFound {
					fmt.Println("##### CLI LOGS: #####")
					fmt.Println(sampleLogs)
					fmt.Println("###############")
				}
				Expect(patternFound).To(BeTrue())
			})

			It("the env var is present", func() {
				patternFound, _ := utils.ContainsPattern(sampleLogs, "K8S_IMAGE=[^/]*/bitnami/os-shell")
				if !patternFound {
					fmt.Println("##### CLI LOGS: #####")
					fmt.Println(sampleLogs)
					fmt.Println("###############")
					kyvernoPods := utils.GetPodsByLabelOrDie(ctx, coreclient, *namespace, "app.kubernetes.io/name=kyverno")
					for _, p := range kyvernoPods.Items {
						podLog := utils.GetContainerLogsOrDie(ctx, coreclient, *namespace, p.GetName(), "kyverno")
						fmt.Println("##### LOGS Kyverno POD: #####")
						fmt.Println(p.GetName())
						fmt.Println(podLog)
						fmt.Println("###############")
					}
				}
				Expect(patternFound).To(BeTrue())
			})
		})
	})
})

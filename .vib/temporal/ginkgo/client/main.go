// Copyright Broadcom, Inc. All Rights Reserved.
// SPDX-License-Identifier: APACHE-2.0

package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/contrib/envconfig"
	"go.temporal.io/sdk/worker"
	"go.temporal.io/sdk/workflow"
)

func greet(ctx context.Context, name string) (string, error) {
	return fmt.Sprintf("Hello %s", name), nil
}

func sayHelloWorkflow(ctx workflow.Context, name string) (string, error) {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: time.Second * 10,
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	var result string
	err := workflow.ExecuteActivity(ctx, greet, name).Get(ctx, &result)
	if err != nil {
		return "", err
	}

	return result, nil
}

func main() {
	c, err := client.Dial(envconfig.MustLoadDefaultClientOptions())
	if err != nil {
		log.Fatalln("Unable to create client", err)
	}
	defer c.Close()

	// Create worker and register workflow and activity
	w := worker.New(c, "my-task-queue", worker.Options{})
	w.RegisterWorkflow(sayHelloWorkflow)
	w.RegisterActivity(greet)

	// Run worker in background
	go func() {
		err := w.Run(worker.InterruptCh())
		// Don’t use Expect here (would panic outside Ginkgo goroutine)
		if err != nil {
			log.Fatalln("Unable to run worker:", err)
		}
	}()

	// Give the worker a moment to start
	time.Sleep(500 * time.Millisecond)

	// Start a workflow execution
	options := client.StartWorkflowOptions{
		ID:        "my-workflow-id",
		TaskQueue: "my-task-queue",
	}
	we, err := c.ExecuteWorkflow(context.Background(), options, sayHelloWorkflow, "buddy")
	if err != nil {
		log.Fatalln("Unable to execute workflow", err)
	}

	var result string
	err = we.Get(context.Background(), &result)
	if err != nil {
		log.Fatalln("Unable to get workflow result", err)
	}

	log.Println("Workflow result:", result)

	// Stop the worker
	w.Stop()
}

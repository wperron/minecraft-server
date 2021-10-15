package main

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambdacontext"
)

func TestEvent(t *testing.T) {
	d := time.Now().Add(50 * time.Millisecond)
	os.Setenv("AWS_LAMBDA_FUNCTION_NAME", "blank-go")
	ctx, cancel := context.WithDeadline(context.Background(), d)
	defer cancel()

	ctx = lambdacontext.NewContext(ctx, &lambdacontext.LambdaContext{
		AwsRequestID:       "495b12a8-xmpl-4eca-8168-160484189f99",
		InvokedFunctionArn: "arn:aws:lambda:us-east-2:123456789012:function:blank-go",
	})
	event := events.CloudwatchLogsEvent{
		AWSLogs: events.CloudwatchLogsRawData{
			Data: "H4sICKfntl4AA2V4YW1wbGUuanNvbgBNj8FuwjAQRO/5ipXPlbDBbUJukRoQUimHcIuiKm1WqStiR2sDQoh/r52QlotlzxvPzl4jANahtXWL+0uPLAX2mu2zj21eFNk6Z0/BYM4aKSAxX8jnlzhZ+suIDqZdkzn2gTq07m16T7RwhHX3gO/CwO3x036R6p0yeqUODsl6Z+kRjP5RZF6opsD8hNr9267D6ZFqwhAMdNOIIX+MUX4/V3ehopCSSzlfJjHn/M9x3z98L0WSLkTK4wrKAumEBO7b921mm/fVrkrh3COR0fBjlMbGQ4S27pANWbfQM7pFv56DczZWAQAA",
		},
	}

	res, err := handleRequest(ctx, event)
	if err != nil {
		t.Errorf("Got error: %s\n", err)
	}
	t.Logf("Result: %s\n", res)
}

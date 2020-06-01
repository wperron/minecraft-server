package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatchevents"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/ec2"
)

var region *string
var table *string
var serverId *string
var instance *string
var rule *string

func init() {
	envRegion, ok := os.LookupEnv("AWS_REGION")
	if ok {
		region = aws.String(envRegion)
	} else {
		region = aws.String("ca-central-1")
	}

	envTable, ok := os.LookupEnv("TABLE")
	if ok {
		table = aws.String(envTable)
	}

	envServer, ok := os.LookupEnv("SERVER_ID")
	if ok {
		serverId = aws.String(fmt.Sprintf("SERVER#%s", envServer))
	}

	envInstance, ok := os.LookupEnv("INSTANCE_ID")
	if ok {
		instance = aws.String(envInstance)
	}

	envRule, ok := os.LookupEnv("RULE_NAME")
	if ok {
		rule = aws.String(envRule)
	}
}

func handleRequest(ctx context.Context) (string, error) {
	sess := session.Must(session.NewSession())
	config := &aws.Config{Credentials: sess.Config.Credentials, Region: region}
	dyn := dynamodb.New(sess, config)
	compute := ec2.New(sess, config)
	events := cloudwatchevents.New(sess, config)

	// Disable the player monitor event to avoid closing the server before anyone has a chance to join.
	log.Println("Disabling the activity monitor event rule.")
	if err := stopMonitorEvent(events, rule); err != nil {
		return "", err
	}

	// Re-enable the player monitor event after execution
	defer restartMonitorEvent(events, rule)

	// Reset the last activity time to give the server at least 30 minutes of uptime.
	log.Println("Resetting the last_activity time to current time.")
	now := time.Now().Unix()
	if err := resetLastActivity(dyn, table, serverId, now); err != nil {
		return "", err
	}

	// Start the EC2 instance running the minecraft server. The minecraft process will start automatically.
	log.Println("Starting the EC2 instance.")
	if err := startServer(compute, instance); err != nil {
		return "", err
	}
	log.Println("EC2 instance started.")

	return "", nil
}

func stopMonitorEvent(e *cloudwatchevents.CloudWatchEvents, rule *string) error {
	if _, err := e.DisableRule(&cloudwatchevents.DisableRuleInput{Name: rule}); err != nil {
		return err
	}
	return nil
}

func resetLastActivity(d *dynamodb.DynamoDB, table, serverId *string, utime int64) error {
	if _, err := d.UpdateItem(&dynamodb.UpdateItemInput{
		TableName: table,
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: serverId,
			},
		},
		UpdateExpression: aws.String("set last_activity = :now"),
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":now": {
				N: aws.String(strconv.Itoa(int(utime))),
			},
		},
	}); err != nil {
		return err
	}
	return nil
}

func startServer(e *ec2.EC2, instance *string) error {
	if _, err := e.StartInstances(&ec2.StartInstancesInput{InstanceIds: []*string{instance}}); err != nil {
		return err
	}
	return nil
}

func restartMonitorEvent(e *cloudwatchevents.CloudWatchEvents, rule *string) error {
	if _, err := e.EnableRule(&cloudwatchevents.EnableRuleInput{Name: rule}); err != nil {
		return err
	}
	return nil
}

func main() {
	lambda.Start(handleRequest)
}

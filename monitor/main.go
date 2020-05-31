package main

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/ec2"
)

type Server struct {
	Id           string `json:"PK"`
	PlayerCount  int    `json:"player_count"`
	LastActivity int64  `json:"last_activity"`
}

var region *string
var table *string
var serverId *string
var instance *string

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
}

func handleRequest(ctx context.Context, event events.CloudWatchEvent) (string, error) {
	sess := session.Must(session.NewSession())
	config := &aws.Config{Credentials: sess.Config.Credentials, Region: region}
	dyn := dynamodb.New(sess, config)
	compute := ec2.New(sess, config)

	server, err := getServerInfo(dyn, table, serverId)
	if err != nil {
		return "", nil
	}

	// zero-value for int64 means the field is not initialized
	if server.LastActivity == 0 {
		fmt.Println("There is no last_activity defined for the server, defaulting to current time")
		server.LastActivity = time.Now().Unix()
	}

	last := time.Since(time.Unix(server.LastActivity, 0))
	running, err := isRunning(compute, instance)
	if err != nil {
		return "", err
	}

	if server.PlayerCount == 0 && last.Minutes() > 30 && running {
		fmt.Println("Closing server after 30 minutes of inactivity.")
		if err := closeServer(compute, instance); err != nil {
			return "", err
		}
	} else if server.PlayerCount > 0 {
		if err := updateActivityTime(server, dyn, table, serverId); err != nil {
			return "", err
		}
	} else {
		fmt.Println("Nothing to do.")
	}

	return "", nil
}

func getServerInfo(dynamo *dynamodb.DynamoDB, table, serverId *string) (Server, error) {
	out, err := dynamo.GetItem(&dynamodb.GetItemInput{
		TableName: table,
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: serverId,
			},
		},
	})

	if err != nil {
		fmt.Printf("ERROR: cloud not get item with key [ %s ] in table [ %s ].\n", *serverId, *table)
		return Server{}, err
	}

	var server Server
	if err := dynamodbattribute.UnmarshalMap(out.Item, &server); err != nil {
		return Server{}, err
	}

	return server, nil
}

func updateActivityTime(s Server, dynamo *dynamodb.DynamoDB, table, serverId *string) error {
	s.LastActivity = time.Now().Unix()

	_, err := dynamo.UpdateItem(&dynamodb.UpdateItemInput{
		TableName: table,
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: serverId,
			},
		},
		UpdateExpression: aws.String("set last_activity = :now"),
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":now": {
				N: aws.String(strconv.Itoa(int(s.LastActivity))),
			},
		},
	})

	if err != nil {
		return err
	}

	return nil
}

func isRunning(e *ec2.EC2, instance *string) (bool, error) {
	describe, err := e.DescribeInstanceStatus(&ec2.DescribeInstanceStatusInput{
		InstanceIds: []*string{instance},
	})

	if err != nil {
		return false, err
	}

	return len(describe.InstanceStatuses) > 0 && *describe.InstanceStatuses[0].InstanceState.Name == ec2.InstanceStateNameRunning, nil
}

func closeServer(e *ec2.EC2, instance *string) error {
	if _, err := e.StopInstances(&ec2.StopInstancesInput{InstanceIds: []*string{instance}}); err != nil {
		return err
	}
	return nil
}

func main() {
	lambda.Start(handleRequest)
}

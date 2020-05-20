package main

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

func handleRequest(ctx context.Context, event events.CloudwatchLogsEvent) (string, error) {
	fmt.Printf("Processing Data: %s\n", event.AWSLogs.Data)
	sess := session.Must(session.NewSession())
	dyn := dynamodb.New(sess, &aws.Config{Credentials: sess.Config.Credentials, Region: aws.String("ca-central-1")})
	logs, err := event.AWSLogs.Parse()
	if err != nil {
		fmt.Println("Error parsing the raw log data.")
		return "", errors.New("failed to parse raw log data.")
	}

	diff := 0
	for _, l := range logs.LogEvents {
		if strings.Contains(l.Message, "joined") {
			diff++
		} else if strings.Contains(l.Message, "left") {
			diff--
		} else {
			fmt.Printf("WARN: expected log line [ %s ] to refer to a player entering or leaving the game.\n", l.Message)
		}
	}

	update := &dynamodb.UpdateItemInput{
		TableName: aws.String("minecraft-shipwreck-1"),
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: aws.String("SERVER#shipwreck"),
			},
		},
		UpdateExpression: aws.String("set player_count = player_count + :diff"),
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":diff": {
				N: aws.String(strconv.Itoa(diff)),
			},
		},
	}

	_, err = dyn.UpdateItem(update)
	if err != nil {
		fmt.Println("Error updating the player count.")
		return "", errors.New(err.Error())
	}

	return fmt.Sprintf("DONE: successfully updated the player count.\n"), nil
}

func main() {
	lambda.Start(handleRequest)
}

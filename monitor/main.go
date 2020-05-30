package main

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

type Server struct {
	Id           string `json:"PK"`
	PlayerCount  int    `json:"player_count"`
	LastActivity int64  `json:"last_activity"`
}

func handleRequest(ctx context.Context, event events.CloudWatchEvent) (string, error) {
	sess := session.Must(session.NewSession())
	dyn := dynamodb.New(sess, &aws.Config{Credentials: sess.Config.Credentials, Region: aws.String("ca-central-1")})
	table := aws.String("minecraft-shipwreck-1")

	out, err := dyn.GetItem(&dynamodb.GetItemInput{
		TableName: table,
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: aws.String("SERVER#shipwreck"),
			},
		},
	})

	if err != nil {
		fmt.Printf("ERROR: cloud not get item with key [ %s ] in table [ %s ].\n", "minecraft-shipwreck-1", "SERVER#shipwreck")
		return "", err
	}

	var server Server
	if err := dynamodbattribute.UnmarshalMap(out.Item, &server); err != nil {
		return "", err
	}

	// zero-value for int64 means the field is not initialized
	if server.LastActivity == 0 {
		fmt.Println("There is no last_activity defined for the server, defaulting to current time")
		server.LastActivity = time.Now().Unix()
	}

	last := time.Since(time.Unix(server.LastActivity, 0))
	if server.PlayerCount == 0 && last.Minutes() > 30 {
		fmt.Println("Closing server after 30 minutes of inactivity.")
	} else if server.PlayerCount > 0 {
		server.LastActivity = time.Now().Unix()
		if err != nil {
			return "", err
		}

		_, err = dyn.UpdateItem(&dynamodb.UpdateItemInput{
			TableName: table,
			Key: map[string]*dynamodb.AttributeValue{
				"PK": {
					S: aws.String("SERVER#shipwreck"),
				},
			},
			UpdateExpression: aws.String("set last_activity = :now"),
			ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
				":now": {
					N: aws.String(strconv.Itoa(int(server.LastActivity))),
				},
			},
		})

		if err != nil {
			return "", err
		}
	}

	return "", nil
}

func main() {
	lambda.Start(handleRequest)
}

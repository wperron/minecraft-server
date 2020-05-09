package main

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handleRequest(ctx context.Context, event events.CloudwatchLogsEvent) (string, error) {
	fmt.Printf("Processing Data: %s\n", event.AWSLogs.Data)
	logs, err := event.AWSLogs.Parse()
	if err != nil {
		fmt.Println("Error parsing the raw log data.")
		return "", errors.New("failed to parse raw log data.")
	}

	players := make(map[string]int)
	for _, l := range logs.LogEvents {
		player := fmt.Sprintf(strings.Split(strings.Split(l.Message, ": ")[1], " ")[0])
		if strings.Contains(l.Message, "joined") {
			players[player] = 1
		} else if strings.Contains(l.Message, "left") {
			players[player] = 0
		} else {
			fmt.Printf("WARN: expected log line [ %s ] to refer to a player entering or leaving the game.\n", l.Message)
		}
	}

	playerNames := ""
	for p, o := range players {
		if o == 1 {
			playerNames += fmt.Sprintf("%s, ", p)
		}
	}
	return playerNames, nil
}

func main() {
	lambda.Start(handleRequest)
}

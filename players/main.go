package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
)

func main() {
	region := "ca-central-1"
	sess := session.Must(session.NewSession())
	svc := cloudwatchlogs.New(sess, &aws.Config{Credentials: sess.Config.Credentials, Region: &region})

	group := "minecraft-server-log"
	stream := "i-061ad4290dee60a65"
	filter := "?\"joined the game\" ?\"left the game\""
	logs, err := svc.FilterLogEvents(&cloudwatchlogs.FilterLogEventsInput{
		LogGroupName:   &group,
		LogStreamNames: []*string{&stream},
		FilterPattern:  &filter,
	})

	if err != nil {
		fmt.Printf("Error: could not perform fitler log events: %s\n", err)
		os.Exit(1)
	}

	players := make(map[string]int)
	for _, l := range logs.Events {
		// count unique players
		player := strings.Split(strings.Split(*l.Message, ": ")[1], " ")[0]

		// adjust player count
		if strings.Contains(*l.Message, "joined") {
			players[player] = 1
		} else if strings.Contains(*l.Message, "left") {
			players[player] = 0
		}
	}

	fmt.Printf("Current number of players: %d\n", countPlayers(players))
	fmt.Printf("Unique players: \n")
	for p, _ := range players {
		fmt.Println(p)
	}
}

func countPlayers(players map[string]int) int {
	total := 0
	for _, v := range players {
		total += v
	}
	return total
}

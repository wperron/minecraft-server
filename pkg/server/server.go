package server

import (
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudwatchevents"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/ec2"
)

type Server struct {
	Region        string
	InstanceId    string
	HeartbeatRule string
	TableName     string
	Status        *ServerStatus
}

type ServerStatus struct {
	Id           string `json:"PK"`
	PlayerCount  int    `json:"player_count"`
	LastActivity int64  `json:"last_activity"`
}

func New(region, instanceId, heartbeatRule, tableName, serverPk string, d *dynamodb.DynamoDB) (*Server, error) {
	status, err := getServerInfo(d, &tableName, &serverPk)
	if err != nil {
		return nil, err
	}

	return &Server{
		Region:        region,
		InstanceId:    instanceId,
		HeartbeatRule: heartbeatRule,
		TableName:     tableName,
		Status:        status,
	}, nil
}

func getServerInfo(dynamo *dynamodb.DynamoDB, table, serverId *string) (*ServerStatus, error) {
	out, err := dynamo.GetItem(&dynamodb.GetItemInput{
		TableName: table,
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: serverId,
			},
		},
	})

	if err != nil {
		return nil, err
	}

	var serverStatus ServerStatus
	if err := dynamodbattribute.UnmarshalMap(out.Item, &serverStatus); err != nil {
		return nil, err
	}

	return &serverStatus, nil
}

func (s *Server) setLastHeartbeat(d *dynamodb.DynamoDB, utime int64) error {
	if _, err := d.UpdateItem(&dynamodb.UpdateItemInput{
		TableName: &s.TableName,
		Key: map[string]*dynamodb.AttributeValue{
			"PK": {
				S: "SERVER#shipwreck", // TODO @wperron change for instance variable
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

func (s *Server) isRunning(e *ec2.EC2) bool {
	describe, err := e.DescribeInstanceStatus(&ec2.DescribeInstanceStatusInput{
		InstanceIds: []*string{&s.InstanceId},
	})

	if err != nil {
		return false, err
	}

	return len(describe.InstanceStatuses) > 0 && *describe.InstanceStatuses[0].InstanceState.Name == ec2.InstanceStateNameRunning, nil
}

func (s *Server) startServer(e *ec2.EC2) error {
	if _, err := e.StartInstances(&ec2.StartInstancesInput{InstanceIds: []*string{&s.InstanceId}}); err != nil {
		return err
	}
	return nil
}

func (s *Server) closeServer(e *ec2.EC2) error {
	if _, err := e.StopInstances(&ec2.StopInstancesInput{InstanceIds: []*string{&s.InstanceId}}); err != nil {
		return err
	}
	return nil
}

func (s *Server) stopMonitorEvent(e *cloudwatchevents.CloudWatchEvents) error {
	if _, err := e.DisableRule(&cloudwatchevents.DisableRuleInput{Name: &s.HeartbeatRule}); err != nil {
		return err
	}
	return nil
}

func (s *Server) restartMonitorEvent(e *cloudwatchevents.CloudWatchEvents) error {
	if _, err := e.EnableRule(&cloudwatchevents.EnableRuleInput{Name: &s.HeartbeatRule}); err != nil {
		return err
	}
	return nil
}

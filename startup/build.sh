#!/bin/bash
GOOS=linux GOARCH=amd64 go build -o main main.go
zip function.zip main
aws lambda update-function-code \
  --function-name minecraft-shipwreck-startup \
  --zip-file fileb://function.zip \
  --publish
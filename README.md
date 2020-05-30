# minecraft-server
CloudWatch Logs subsribtions and actions

to build individual lambda packages:

```bash
cd lambda/
GOOS=linux GOARCH=amd64 go build -o main main.go
```

don't forget to update the handler of the lambda in the console.
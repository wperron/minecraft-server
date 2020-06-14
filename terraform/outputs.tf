output "state_bucket" {
  value = aws_s3_bucket.state.id
}

output "lock_table" {
  value = aws_dynamodb_table.state.name
}

output "mc_server_instance" {
  value = aws_instance.mc_server.id
}

output "mc_server_public_ip" {
  value = aws_instance.mc_server.public_ip
}

output "mc_server_companion_table" {
  value = aws_dynamodb_table.server.name
}

output "heartbeat_rule_name" {
  value = aws_cloudwatch_event_rule.heartbeat.name
}

output "heartbeat_function_name" {
  value = aws_lambda_function.heartbeat.function_name
}

output "player_listener_function_name" {
  value = aws_lambda_function.players.function_name
}

output "startup_function_name" {
  value = aws_lambda_function.startup.function_name
}
locals {
  schema_version = 1
}

resource "aws_dynamodb_table" "server" {
  name         = "${var.app}-${var.group}-${local.schema_version}"
  hash_key     = "PK"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "PK"
    type = "S"
  }

  tags = local.tags
}

resource "aws_lambda_function" "players" {
  function_name = "${var.app}-${var.group}-player-listener"
  filename      = "${path.module}/../players/function.zip"
  role          = aws_iam_role.this.arn
  handler       = "main"
  publish       = true
  runtime       = "go1.x"
  memory_size   = 512
  timeout       = 15

  environment {
    variables = {
      "TABLE"       = aws_dynamodb_table.server.name
      "SERVER_ID"   = var.group
      "INSTANCE_ID" = aws_instance.mc_server.id
    }
  }

  tags = local.tags
}

resource "aws_lambda_function" "heartbeat" {
  function_name = "${var.app}-${var.group}-heartbeat"
  filename      = "${path.module}/../monitor/function.zip"
  role          = aws_iam_role.this.arn
  handler       = "main"
  publish       = true
  runtime       = "go1.x"
  memory_size   = 512
  timeout       = 15

  environment {
    variables = {
      "TABLE"       = aws_dynamodb_table.server.name
      "SERVER_ID"   = var.group
      "INSTANCE_ID" = aws_instance.mc_server.id
      "RULE_NAME"   = aws_cloudwatch_event_rule.heartbeat.name
    }
  }

  tags = local.tags
}

resource "aws_lambda_function" "startup" {
  function_name = "${var.app}-${var.group}-startup"
  filename      = "${path.module}/../startup/function.zip"
  role          = aws_iam_role.this.arn
  handler       = "main"
  publish       = true
  runtime       = "go1.x"
  memory_size   = 512
  timeout       = 15

  environment {
    variables = {
      "TABLE"       = aws_dynamodb_table.server.name
      "SERVER_ID"   = var.group
      "INSTANCE_ID" = aws_instance.mc_server.id
      "RULE_NAME"   = aws_cloudwatch_event_rule.heartbeat.name
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "heartbeat" {
  name                = "${var.app}-${var.group}-heartbeat"
  schedule_expression = "cron(0/5 * * * ? *)"
  description         = "Checks up on a minecraft server config at regular interval"
  tags                = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_heartbeat" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.heartbeat.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.heartbeat.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_mc_logs" {
  statement_id   = "AllowExecutionFromCloudWatch"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.players.function_name
  principal      = "logs.ca-central-1.amazonaws.com"
  source_arn     = aws_cloudwatch_log_group.this.arn
  source_account = data.aws_caller_identity.this.account_id
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "permissions" {
  statement {
    actions = [
      "dynamodb:*Item",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:Wait",
    ]
    resources = [
      aws_dynamodb_table.server.arn,
    ]
  }

  statement {
    actions = [
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:DesribeInstanceStatus",
    ]
    resources = [
      aws_instance.mc_server.arn,
    ]
  }
}

data "aws_iam_policy_document" "logging" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.app}-${var.group}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "inline_permissions" {
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.permissions.json
}

resource "aws_iam_role_policy" "inline_logging" {
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.logging.json
}
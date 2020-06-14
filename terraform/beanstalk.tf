resource "aws_elastic_beanstalk_application" "this" {
  name        = "${var.app}-${var.group}-scallywag"

  tags = local.tags
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = "${title(var.app)}${title(var.group)}Scallywag-env"
  application         = aws_elastic_beanstalk_application.this.name
  tier                = "WebServer"
  solution_stack_name = "64bit Amazon Linux 2 v5.0.2 running Node.js 12"

  lifecycle {
    ignore_changes = [
      version_label,
      all_settings,
    ]
  }

  tags = local.tags
}

data "aws_iam_policy_document" "scallywag_permissions" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:ca-central-1:759227299492:parameter/scallywag-bot-secret"]
  }

  statement {
    actions   = ["lambda:*"]
    resources = [aws_lambda_function.startup.arn]
  }
}

data "aws_iam_policy_document" "eb_ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eb_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "sts:ExternalId"
      values = ["elasticbeanstalk"]
    }
  }
}

resource "aws_iam_role" "eb_ec2_role" {
  name               = "aws-elasticbeanstalk-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.eb_ec2_assume.json
}

resource "aws_iam_policy" "scallywag_permissions" {
  name   = "scallywag-bot-application-permissions"
  policy = data.aws_iam_policy_document.scallywag_permissions.json
}

resource "aws_iam_role_policy_attachment" "scallywag_permissions" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = aws_iam_policy.scallywag_permissions.arn
}

resource "aws_iam_role_policy_attachment" "web" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "docker" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "worker" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role" "eb_service_role" {
  name = "aws-elasticbeanstalk-service-role"
  assume_role_policy = data.aws_iam_policy_document.eb_assume.json
}

resource "aws_iam_role_policy_attachment" "health" {
  role = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "service" {
  role = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}
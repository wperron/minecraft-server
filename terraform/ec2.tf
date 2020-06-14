data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "mc_server" {
  ami                     = "ami-0edd51cc29813e254"
  instance_type           = "m5a.large"
  availability_zone       = "ca-central-1a"
  ebs_optimized           = true
  disable_api_termination = true
  key_name                = "ubuntu" # @wperron : this is my personal key-pair
  security_groups = [
    aws_security_group.mc_server.name,
  ]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = aws_iam_instance_profile.mc_server.name

  root_block_device {
    encrypted   = false
    iops        = 100
    volume_size = 30
    volume_type = "gp2"
  }

  tags        = merge(local.tags, { "Name" = "${var.app}-${var.group}-4" })
  volume_tags = merge(local.tags, { "Name" = "${var.app}-${var.group}-vol-1" })
}

resource "aws_security_group" "mc_server" {
  name        = "${var.app}-server"
  description = "minecraft-server created 2020-05-03T15:54:38.338-04:00" # value from the initial creation through the console wizard

  ingress {
    description = "minecraft server port whitelist"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 25565
    to_port     = 25565
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  vpc_id = data.aws_vpc.default.id
  tags   = local.tags
}

resource "aws_security_group_rule" "mc_server" {
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port         = 22
  ipv6_cidr_blocks  = []
  prefix_list_ids   = []
  protocol          = "tcp"
  security_group_id = aws_security_group.mc_server.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "mc_server-1" {
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port         = 25565
  ipv6_cidr_blocks  = []
  prefix_list_ids   = []
  protocol          = "tcp"
  security_group_id = aws_security_group.mc_server.id
  to_port           = 25565
  type              = "ingress"
}

resource "aws_security_group_rule" "mc_server-2" {
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port         = 0
  ipv6_cidr_blocks  = []
  prefix_list_ids   = []
  protocol          = "-1"
  security_group_id = aws_security_group.mc_server.id
  to_port           = 0
  type              = "egress"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "minecraft-server-log"

  tags = local.tags
}

resource "aws_iam_role" "mc_server" {
  name               = "${var.app}-${var.group}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy" "cw_agent" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "instance_cw_agent" {
  role       = aws_iam_role.mc_server.name
  policy_arn = data.aws_iam_policy.cw_agent.arn
}

resource "aws_iam_instance_profile" "mc_server" {
  name = "${var.app}-${var.group}-instance-profile"
  role = aws_iam_role.mc_server.name
}
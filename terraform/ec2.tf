data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "mc_server" {
  ami                     = var.ami_id
  instance_type           = "m5a.large"
  availability_zone       = "ca-central-1a"
  ebs_optimized           = true
  key_name                = "ubuntu-B550M-20211015" # @wperron : this is my personal key-pair
  security_groups = [
    aws_security_group.mc_server.name,
  ]
  associate_public_ip_address = true
  source_dest_check           = true
  iam_instance_profile        = aws_iam_instance_profile.mc_server.name
  user_data = templatefile("${path.module}/templates/userdata.tpl.sh", {
    loki_username = var.loki_username
    loki_password = var.loki_password
    prom_username = var.prom_username
    prom_password = var.prom_password
  })

  # This setting is counter intuitive; Setting "disable_something" to false would
  # imply that it _enables_ the setting, but as per the [documentation][1] setting
  # this value to 'true' actually enables deletion protection. This should
  # probably be set to true for safety, but what the hell, this is a side project
  # that's only used by me /shrug
  #
  # [1]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#disable_api_termination
  disable_api_termination = false

  root_block_device {
    encrypted   = false
    volume_size = 30
    volume_type = "gp2"
  }

  tags        = merge(local.tags, { "Name" = "${var.app}-${var.group}-instance" })
  volume_tags = merge(local.tags, { "Name" = "${var.app}-${var.group}-volume" })
}

resource "aws_security_group" "mc_server" {
  name        = "${var.app}-server"
  description = "minecraft-server" # value from the initial creation through the console wizard

  ingress {
    description = "minecraft server port whitelist"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 25565
    to_port     = 25565
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

resource "aws_iam_role" "mc_server" {
  name               = "${var.app}-${var.group}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_instance_profile" "mc_server" {
  name = "${var.app}-${var.group}-instance-profile"
  role = aws_iam_role.mc_server.name
}
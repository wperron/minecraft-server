packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "ubuntu" {
  filters = {
    virtualization-type = "hvm"
    name                = "ubuntu/images/*/ubuntu-hirsute-21.04-amd64-server-*"
    root-device-type    = "ebs"
  }
  owners      = ["099720109477"]
  most_recent = true
  region      = "ca-central-1"
}

source "amazon-ebs" "ssm" {
  ami_name = "packer build {{timestamp}}"
  instance_type = "t3.small"
  region = "ca-central-1"
  source_ami = data.amazon-ami.ubuntu.id
  ssh_username = "ubuntu"
  communicator = "ssh"
}

build {
  sources = ["source.amazon-ebs.ssm"]

  provisioner "file" {
    source = "minecraft.service"
    destination = "/tmp/minecraft.service"
  }

  provisioner "shell"{
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"
    ]
  }

  provisioner "shell" {
    script = "./provision.sh"
  }
}

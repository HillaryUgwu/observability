terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_ami" "amazon_linux_2" {
 most_recent = true

 filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
 }

 #filter {
 #   name   = "virtualization-type"
 #   values = ["hvm"]
 #}

 owners = ["amazon"]
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "tfstate-bucket-observability"
  force_destroy = true
}

terraform {
  backend "s3" {
    bucket  = "tfstate-bucket-observability"
    key     = "build/terraform.tfstate"
    region  = "us-east-1"
  }
}

variable "instance_tags" {
  description = "List of tag names for the instances"
  type        = list(string)
  default     = ["controller", "node1", "node2"]
}

resource "aws_instance" "ec2_instances" {
  count         = 3
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro" 
  
  tags = {
    Name = var.instance_tags[count.index]
  }

# Conditional execution of the provisioner for the "controller" instance only
  provisioner "remote-exec" {
    when    = "controller"
    inline = [
      "sudo yum update -y",
      "sudo yum install ansible -y"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}
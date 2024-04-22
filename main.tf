terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

#data "aws_key_pair" "ohary_key"{
#  key_name                = "ohary"
#}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "ssh_key" {
 algorithm = "RSA"
 rsa_bits = 4096
}

resource "aws_key_pair" "ssh_key" {
 key_name   = "ssh_key"
 public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_security_group" "controller_sg" {
 name        = "controller-sg"
 description = "Security group for the controller instance"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["93.206.39.2/32"]
 }

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
 }

 tags = {
    Name = "controller-sg"
 }
}

resource "aws_security_group" "node_sg" {
 name        = "node-sg"
 description = "Security group for the node instances"

 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.controller_sg.id]
 }

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
 }

 tags = {
    Name = "node-sg"
 }
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "tfstate-bucket-observability"
  #force_destroy = true
  lifecycle {
    prevent_destroy = true
  }
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

resource "aws_instance" "controller" {
 ami                     = data.aws_ami.amazon_linux_2023.id
 instance_type           = "t2.micro"
 key_name                = "ohary"
 vpc_security_group_ids  = [aws_security_group.controller_sg.id]

 tags = {
    Name                 = "controller"
 }
  user_data   = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install ansible -y
                sudo hostnamectl set-hostname controller
                mkdir -p /home/ec2-user/.ssh
                echo '${tls_private_key.ssh_key.private_key_pem}' > /home/ec2-user/.ssh/id_rsa
                chmod 600 /home/ec2-user/.ssh/id_rsa
                EOF

}

resource "aws_instance" "node" {
 count                     = 2
 ami                       = data.aws_ami.amazon_linux_2023.id
 instance_type             = "t2.micro"
 key_name                  = "ohary"
 vpc_security_group_ids    = [aws_security_group.node_sg.id]

 tags = {
    Name                   = "node-${count.index + 1}"
 }

 user_data  = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname node${count.index + 1}
              mkdir -p /home/ec2-user/.ssh
              echo '${tls_private_key.ssh_key.public_key_openssh}' > /home/ec2-user/.ssh/authorized_keys
              chmod 600 /home/ec2-user/.ssh/authorized_keys
              EOF
}

output "controller_public_ip" {
 description = "Public IP address of the controller instance"
 value       = aws_instance.controller.public_ip
}

output "node_public_ips" {
 description = "Public IP addresses of the node instances"
 value       = aws_instance.node[*].public_ip
}

resource "null_resource" "output_ips" {
 provisioner "local-exec" {
    command = "echo 'Controller: ${aws_instance.controller.public_ip}\nNodes: ${join(", ", aws_instance.node[*].public_ip)}' > ips.txt"
 }
 triggers = {
    controller_ip = aws_instance.controller.public_ip
    node_ips      = join(",", aws_instance.node[*].public_ip)
 }
}

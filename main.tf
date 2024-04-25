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

# Save private key locally.
resource "local_sensitive_file" "private_key" {
 content         = tls_private_key.ssh_key.private_key_openssh
 filename        = "${path.module}/.ssh/id_rsa"
 file_permission = "0600"
 depends_on      = [tls_private_key.ssh_key]
}

data "external" "fetch_ip" {
  program = ["bash", "${path.module}/bin/workspace_ip"]
}

resource "aws_security_group" "controller_sg" {
 name        = "controller-sg"
 description = "Security group for the controller instance"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.fetch_ip.result["ip"]}/32"]
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
  key_name                = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids  = [aws_security_group.controller_sg.id]

  tags = {
    Name                  = "controller"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ssh_key.private_key_openssh
    host        = self.public_ip
    host_key    = ""
  }

  # Provisioner to copy the 'src' folder to the remote instance
  provisioner "file" {
    source      = "src/" # Ensure there's a trailing slash to copy the contents directly
    destination = "/home/ec2-user"
  }

  #provisioner "remote-exec" {
  #  inline = [
  #    "echo '${tls_private_key.ssh_key.private_key_openssh}' > /home/ec2-user/id_rsa",
  #    "chmod +x /home/ec2-user/bootstrap_controller",
  #    "chmod +x /home/ec2-user/download_playbook",
  #    "chmod +x /home/ec2-user/copy_key_2node",
  #    "bash /home/ec2-user/bootstrap_controller",
  #    "bash /home/ec2-user/download_playbook",
  #    #"bash /home/ec2-user/copy_key_2node",
  #    #"ansible-playbook -i inventory.ini ansible/playbook.yml"
  #  ]
  #}

  user_data   = <<-EOF
               #!/bin/bash
               sudo yum update -y
               sudo yum install ansible -y
               sudo hostnamectl set-hostname controller
               echo '${tls_private_key.ssh_key.private_key_openssh}' > /home/ec2-user/id_rsa
               chmod 600 /home/ec2-user/id_rsa
               chown -R ec2-user:ec2-user /home/ec2-user/id_rsa
               chmod +x /home/ec2-user/download_playbook
               chmod +x /home/ec2-user/copy_key_2node
               bash /home/ec2-user/bootstrap_controller
               bash /home/ec2-user/download_playbook
               #"bash /home/ec2-user/copy_key_2node
               #"ansible-playbook -i inventory.ini ansible/playbook.yml
               EOF

}

resource "local_file" "ansible_inventory" {
  content = templatefile("src/inventory.ini", {
    ip_addrs = [for i in aws_instance.node:i.private_ip]
  })
  filename = "src/inventory.ini"
}

resource "aws_instance" "node" {
 count                     = 2
 ami                       = data.aws_ami.amazon_linux_2023.id
 instance_type             = "t2.micro"
 key_name                  = aws_key_pair.ssh_key.key_name
 vpc_security_group_ids    = [aws_security_group.node_sg.id]

 tags = {
    Name                   = "node-${count.index + 1}"
 }

 user_data  = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname node${count.index + 1}
              EOF
}

output "controller_private_ip" {
 description = "Private IP address of the controller instance"
 value       = aws_instance.controller.private_ip
}

output "node_private_ip" {
 description = "Private IP addresses of the node instances"
 value       = aws_instance.node[*].private_ip
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

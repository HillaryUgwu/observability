
resource "aws_instance" "node" {
 count                     = var.node_instance_count
 ami                       = data.aws_ami.amazon_linux_2023.id
 instance_type             = var.instance_type
 key_name                  = aws_key_pair.ssh_key.key_name
 vpc_security_group_ids    = [aws_security_group.node_sg.id]
 availability_zone         = data.aws_availability_zones.available.names[count.index + 1]

 tags = {
    Name                   = "node-${count.index + 1}"
 }

 user_data  = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname node${count.index + 1}
              EOF
}

resource "aws_security_group" "node_sg" {
  name        = "node-sg"
  description = "Security group for the node instances"

  ingress {
    description = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = [aws_security_group.controller_sg.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }
  ingress {
    description = "Allow traffic to Node exporter server (port 9100 by default)"
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "Allow traffic to Prometheus server (port 9090 by default)"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "Allow traffic to Grafana (port 3000 by default)"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "node-sg"
 }
}



resource "aws_instance" "controller" {
  ami                     = data.aws_ami.amazon_linux_2023.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids  = [aws_security_group.controller_sg.id]
  availability_zone       = data.aws_availability_zones.available.names[0]

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

  provisioner "remote-exec" {
    inline = [
      file("bin/bootstrap_controller"),
      "echo '[nodes]' > inventory.ini",
      "for ip in ${join(" ", [for i in aws_instance.node : i.private_ip])}; do echo $ip >> inventory.ini; done",
      "echo '${tls_private_key.ssh_key.private_key_openssh}' > /home/ec2-user/.ssh/id_rsa",
      "chmod 600 /home/ec2-user/.ssh/id_rsa",
      "chown -R ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa",
      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i inventory.ini ansible/playbook.yml -e 'ansible_ssh_private_key_file=/home/ec2-user/.ssh/id_rsa'"
    ]
  }
}

resource "aws_security_group" "controller_sg" {
 name        = "controller-sg"
 description = "Security group for the controller instance"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.workspace_ip.result["ip"]}/32"]
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

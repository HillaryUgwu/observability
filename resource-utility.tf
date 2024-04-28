
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "tfstate-bucket-observability"
  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_private_key" "ssh_key" {
 algorithm = "RSA"
 rsa_bits = 4096
}

resource "aws_key_pair" "ssh_key" {
 key_name   = "ssh_key"
 public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save private key locally (NOT RECOMMENDED!).
resource "local_sensitive_file" "private_key" {
 content         = tls_private_key.ssh_key.private_key_openssh
 filename        = "${path.module}/.ssh/id_rsa"
 file_permission = "0600"
 depends_on      = [tls_private_key.ssh_key]
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

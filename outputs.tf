
output "controller_private_ip" {
 description = "Private IP address of the controller instance"
 value       = aws_instance.controller.private_ip
}

output "node_private_ip" {
 description = "Private IP addresses of the node instances"
 value       = aws_instance.node[*].private_ip
}

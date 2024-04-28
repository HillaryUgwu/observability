variable "region" {
  description = "The region where resources will be created"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of instance to create"
  default     = "t2.micro"
}

variable "node_instance_count" {
  description = "The number of Node instances to create"
  default     = 2
}
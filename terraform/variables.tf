variable "project_name" {
  description = "Name used for AWS resources."
  type        = string
  default     = "sre-microservices-assignment"
}

variable "aws_region" {
  description = "AWS region where the VM will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "instance_ami" {
  description = "AMI ID for the VM. Use an Ubuntu AMI for the selected region."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name for SSH access."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to connect via SSH."
  type        = string
}

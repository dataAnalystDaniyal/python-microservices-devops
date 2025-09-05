# terraform/variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "AWS Key Pair name for EC2 access"
  type        = string
  default     = "my-key-pair"
}

variable "dockerhub_username" {
  description = "DockerHub username for pulling images"
  type        = string
}

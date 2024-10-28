variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR range for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR range for the private subnets"
  type        = list(string)
}
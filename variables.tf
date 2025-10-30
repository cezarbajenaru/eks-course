#variables will be used here in order to leave the modules as clean and reusable as possible

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "The availability zones for the VPC"
  type        = list(string)
  default     = ["eu-central-1a"]
}


variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "my-cluster"
}
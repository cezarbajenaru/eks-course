#variables will be used here in order to leave the modules as clean and reusable as possible
# VPC variables
variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }

variable "vpc_azs" { type = list(string) }
variable "vpc_private_subnets" { type = list(string) }
variable "vpc_public_subnets" { type = list(string) }

variable "vpc_enable_nat_gateway" { type = bool }
variable "vpc_single_nat_gateway" { type = bool }
variable "vpc_reuse_nat_ips" { type = bool }

variable "vpc_tags" { type = map(string) }

# modules/security_group/ Security Group variables
variable "sg_eks_project" { type = string }
variable "description" { type = string }
variable "ingress_rules" { type = list(string) }
variable "ingress_cidr_blocks" {
  type = list(string)
}

#tags
variable "tags" { type = map(string) }




variable "kubernetes_version" {
  type        = string
  description = "Version of the Kubernetes cluster"
}

variable "eks_managed_node_groups" { type = map(object({
  ami_type       = string
  instance_types = list(string)
  min_size       = number
  max_size       = number
  desired_size   = number
})) }

variable "eks_cluster_name" {
  type        = string
  description = "Kubernetes cluster name" #it needs a cluster name to be able to create the ALB, a separate one from the EKS cluster name because EKS is not yet created when the VPC module is applied
}


variable "wordpress_domain" {
  type        = string
  description = "Wordpress domain name" #used in the wordpress module to create the ingress and used in domain_name root/main.tf
}

#modules/monitoring/log_group/ log group variables

variable "log_group_name" {
  type        = string
  description = "The name of the log group to create the metric filter for"
}

variable "retention_in_days" {
  type        = number
  description = "The retention (days untill auto delete) for the log group"
}


#modules/monitoring/s3_logs/ ALB S3 logs variables
variable "s3_alb_logs_bucket_name" {
  type        = string
  description = "The name of the S3 bucket for ALB logs"
}


#modules/monitoring/alarms/ alarms variables

variable "cpu_alarm_name" {
  description = "The name of the CPU alarm"
  type        = string
}

variable "cpu_alarm_description" {
  description = "The description of the CPU alarm"
  type        = string
}

variable "cpu_metric_name" {
  description = "The name of the CPU metric"
  type        = string
}


variable "cpu_comparison_operator" {
  description = "The comparison operator of the CPU metric"
  type        = string
}

variable "cpu_period" {
  description = "The period of the CPU metric in seconds"
  type        = number
}

variable "cpu_evaluation_periods" {
  description = "The evaluation periods of the CPU metric in minutes"
  type        = number
}

variable "cpu_threshold" {
  description = "The threshold of the CPU metric in percentage"
  type        = number
}

variable "cpu_statistic" {
  description = "The statistic of the CPU metric - Average, Maximum, Minimum, Sum"
  type        = string
}

variable "cpu_alarm_actions" {
  description = "SNS topic ARN to send the alarm to - The actions to take when the alarm is triggered"
  type        = list(string)
  default     = []
}

#modules/monitoring/sns/ SNS variables
variable "sns_name" {
  description = "The name of the SNS topic"
  type        = string
}

variable "email" {
  description = "The email address to send the SNS notifications to"
  type        = string
}
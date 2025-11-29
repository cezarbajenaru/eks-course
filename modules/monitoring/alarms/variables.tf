variable "eks_cluster_name" {
  description = "The name of the EKS cluster - comes from terraform.tfvars in eks section"
  type = string
}

variable "cpu_alarm_name" {
  description = "The name of the CPU alarm"
  type = string
}

variable "cpu_alarm_description" {
  description = "The description of the CPU alarm"
  type = string
}

variable "cpu_metric_name" {
  description = "The name of the CPU metric"
  type = string
}

variable "cpu_create_metric_alarm" {
  description = "Whether to create the CPU metric alarm"
  type = bool
}

variable "cpu_period" {
  description = "The period of the CPU metric in seconds"
  type = number
}

variable "cpu_evaluation_periods" {
  description = "The evaluation periods of the CPU metric in minutes"
  type = number
}

variable "cpu_threshold" {
  description = "The threshold of the CPU metric in percentage"
  type = number
}

variable "cpu_statistic" {
  description = "The statistic of the CPU metric - Average, Maximum, Minimum, Sum"
  type = string
}

variable "alarm_actions" {
  description = "SNS topic ARN to send the alarm to - The actions to take when the alarm is triggered"
  type = list(string)
  default = []
}
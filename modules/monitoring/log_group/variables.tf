variable "log_group_name" {
  type = string
  description = "The name of the log group to create the metric filter for"
}

variable "retention_in_days" {
  type = number
  description = "The retention (days untill auto delete) for the log group"
}
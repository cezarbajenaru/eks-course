variable "log_group_name" {
  type = string
  description = "The name of the log group to create the metric filter for"
}

variable "name" {
  type = string
  description = "The name of the metric filter"
}
variable "pattern" {
  type = string
  description = "The pattern to use for the metric filter"
}

variable "metric_transformation_namespace" {
  type = string
  description = "The namespace of the metric filter"
}

variable "metric_transformation_name" {
  type = string
  description = "The name of the metric filter"
}

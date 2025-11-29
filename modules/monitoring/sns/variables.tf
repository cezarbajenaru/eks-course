variable "sns_name" {
  type = string
  description = "The name of the SNS topic"
}

variable "email" {
  type = string
  description = "The email address to send the SNS notifications to"
}

variable "tags" {
  type = map(string)
  description = "The tags to add to the SNS topic"
}
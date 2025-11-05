variable "name" {
    type = string
}

variable "kubernetes_version" {
    type = string
}

variable "eks_managed_node_groups" {type = map(object({
    ami_type = string
    instance_types = list(string)
    min_size = number
    max_size = number
    desired_size = number
}))}

variable "tags" {
    type = map(string)
}
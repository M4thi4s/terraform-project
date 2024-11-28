variable "metadata_name" {
  type = string
}

variable "label_app" {
  type = string
}

variable "label_tier" {
  type = string
}

variable "container_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "resources_requests" {
  type = map(any)
  default = {
    cpu    = "100m"
    memory = "100Mi"
  }
}

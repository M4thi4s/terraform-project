variable "container_name" {
  description = "Name of the Docker container"
  type        = string
}

variable "image_name" {
  description = "Docker image name"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "build_context" {
  description = "Path to the build context"
  type        = string
  default     = null
}

variable "dockerfile" {
  description = "Path to the Dockerfile"
  type        = string
  default     = null
}

variable "container_ports" {
  description = "List of ports to expose"
  type        = list(object({
    internal = number
    external = optional(number)
  }))
  default = []
}

variable "networks" {
  description = "List of networks to connect"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "volumes" {
  description = "List of volumes"
  type        = list(object({
    host_path      = string
    container_path = string
    type           = optional(string)
  }))
  default = []
}

variable "healthcheck" {
  description = "Healthcheck configuration"
  type = object({
    test         = list(string)
    interval     = optional(string)
    timeout      = optional(string)
    retries      = optional(number)
    start_period = optional(string)
  })
  default = null
}

variable "restart" {
  description = "Restart policy"
  type        = string
  default     = null
}
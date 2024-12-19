variable "front_tier_network" {
  type    = string
  default = "front-tier"
}

variable "back_tier_network" {
  type    = string
  default = "back-tier"
}

variable "postgres_password" {
  default = "postgres"
}
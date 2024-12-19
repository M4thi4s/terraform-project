output "front_tier_network" {
  value = docker_network.front_tier.name
}

output "back_tier_network" {
  value = docker_network.back_tier.name
}

output "postgres_password" {
  value = var.postgres_password
}

output "result" {
  value = "http://127.0.0.1:${docker_container.result.ports[0].external}"
}
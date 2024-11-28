# Build the Docker image if build context is provided
resource "docker_image" "image" {
  count = var.build_context != null ? 1 : 0

  name = "${var.image_name}:${var.image_tag}"

  build {
    context    = var.build_context
    dockerfile = var.dockerfile
  }
}

# Pull the Docker image if no build context is provided
resource "docker_image" "pulled_image" {
  count = var.build_context == null ? 1 : 0

  name = "${var.image_name}:${var.image_tag}"
}

# Create the Docker container
resource "docker_container" "container" {
  name  = var.container_name
  image = var.build_context != null ? docker_image.image[0].name : docker_image.pulled_image[0].name

  dynamic "ports" {
    for_each = var.container_ports
    content {
      internal = ports.value.internal
      external = try(ports.value.external, null)
    }
  }

  dynamic "networks_advanced" {
    for_each = var.networks
    content {
      name = networks_advanced.value
    }
  }

  env = [for k, v in var.environment : "${k}=${v}"]

  volumes = [
    for vol in var.volumes : {
      host_path      = vol.host_path
      container_path = vol.container_path
      type           = lookup(vol, "type", null)
    }
  ]

  dynamic "healthcheck" {
    for_each = var.healthcheck != null ? [var.healthcheck] : []
    content {
      test         = healthcheck.value.test
      interval     = lookup(healthcheck.value, "interval", null)
      timeout      = lookup(healthcheck.value, "timeout", null)
      retries      = lookup(healthcheck.value, "retries", null)
      start_period = lookup(healthcheck.value, "start_period", null)
    }
  }

  restart = var.restart
}

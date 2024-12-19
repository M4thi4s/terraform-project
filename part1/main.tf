terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Networks
resource "docker_network" "front_tier" {
  name = var.front_tier_network
}

resource "docker_network" "back_tier" {
  name = var.back_tier_network
}

# Redis
resource "docker_image" "redis" {
  name = "redis:alpine"
}

resource "docker_container" "redis" {
  name  = "redis"
  image = docker_image.redis.image_id
  networks_advanced {
    name = docker_network.back_tier.name
  }
  volumes {
    host_path      = abspath("../healthchecks")
    container_path = "/healthchecks"
  }
}

# PostgreSQL
resource "docker_image" "postgres" {
  name = "postgres:15-alpine"
}

resource "docker_container" "db" {
    name  = "db"
    image = docker_image.postgres.image_id
    env   = [
      "POSTGRES_PASSWORD=${var.postgres_password}"
    ]
    networks_advanced {
        name = docker_network.back_tier.name
    }
    volumes {
        host_path      = abspath("../healthchecks")
        container_path = "/healthchecks"
    }
    volumes {
        host_path      = abspath("../db-data")
        container_path = "/var/lib/postgresql/data"
    }
}

# Vote
resource "docker_image" "vote" {
  name   = "vote"
  build {
    context    = "../voting-services/vote"
    dockerfile = "Dockerfile"
  }
  // Force the image to be rebuilt if the Dockerfile changes
  triggers = {
    vote_hash = filesha256("../voting-services/vote/Dockerfile")
  }
}

resource "docker_container" "vote1" {
  name  = "vote1"
  image = docker_image.vote.image_id
  networks_advanced {
    name = docker_network.front_tier.name
  }
  networks_advanced {
    name = docker_network.back_tier.name
  }
  depends_on = [docker_container.redis]
}

resource "docker_container" "vote2" {
  name  = "vote2"
  image = docker_image.vote.image_id
  networks_advanced {
    name = docker_network.front_tier.name
  }
  networks_advanced {
    name = docker_network.back_tier.name
  }
  depends_on = [docker_container.redis]
}

# Result
resource "docker_image" "result" {
  name   = "result"
  build {
    context    = "../voting-services/result"
    dockerfile = "Dockerfile"
  }
  // Force the image to be rebuilt if the Dockerfile changes
  triggers = {
    result_hash = filesha256("../voting-services/result/Dockerfile")
  }
}

resource "docker_container" "result" {
  name  = "result"
  image = docker_image.result.image_id
    ports {
    internal = 80
    external = 5050
  }
  ports {
    internal = 9229
    external = 9229
  }
  networks_advanced {
    name = docker_network.front_tier.name
  }
  networks_advanced {
    name = docker_network.back_tier.name
  }
  depends_on = [docker_container.db]
}

# Worker
resource "docker_image" "worker" {
  name   = "worker"
  build {
    context    = "../voting-services/worker"
    dockerfile = "Dockerfile"
  }
  // Force the image to be rebuilt if the Dockerfile changes
  triggers = {
    worker_hash = filesha256("../voting-services/worker/Dockerfile")
  }
}

resource "docker_container" "worker" {
  name  = "worker"
  image = docker_image.worker.image_id
  networks_advanced {
    name = docker_network.back_tier.name
  }
  depends_on = [docker_container.redis, docker_container.db]
}

# Nginx
resource "docker_image" "nginx" {
  name   = "nginx"
  build {
    context    = "../voting-services/nginx"
    dockerfile = "Dockerfile"
  }
  // Force the image to be rebuilt if the Dockerfile changes
  triggers = {
    nginx_hash = filesha256("../voting-services/nginx/Dockerfile")
  }
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = docker_image.nginx.image_id
  ports {
    internal = 8000
    external = 8000
  }
  networks_advanced {
    name = docker_network.front_tier.name
  }
  depends_on = [docker_container.vote1, docker_container.vote2]
}

# Seed
resource "docker_image" "seed" {
  name   = "seed"
  build {
    context    = "../voting-services/seed-data"
    dockerfile = "Dockerfile"
  }
  // Force the image to be rebuilt if the Dockerfile changes
  triggers = {
    seed_hash = filesha256("../voting-services/seed-data/Dockerfile")
  }
}

resource "docker_container" "seed" {
    name  = "seed"
    image = docker_image.seed.image_id
    env = [
        "TARGET_HOST=nginx",
        "TARGET_PORT=8000"
    ]
    networks_advanced {
        name = docker_network.front_tier.name
    }
    depends_on = [docker_container.nginx]
    restart    = "no"
}
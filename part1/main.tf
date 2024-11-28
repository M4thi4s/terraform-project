# Create Docker Networks
resource "docker_network" "front-tier" {
  name = "front-tier"
}

resource "docker_network" "back-tier" {
  name = "back-tier"
}

# Redis Service
module "redis" {
  source = "./deployment"

  container_name = "redis"
  image_name     = "redis"
  image_tag      = "alpine"
  networks       = [docker_network.back-tier.name]
  volumes        = [
    {
      host_path      = "${path.module}/../healthchecks"
      container_path = "/healthchecks"
    }
  ]
  healthcheck = {
    test     = ["/healthchecks/redis.sh"]
    interval = "5s"
  }
}

# PostgreSQL Database Service
module "db" {
  source = "./deployment"

  container_name = "db"
  image_name     = "postgres"
  image_tag      = "15-alpine"
  networks       = [docker_network.back-tier.name]
  environment    = {
    POSTGRES_PASSWORD = "postgres"
  }
  volumes        = [
    {
      host_path      = "db-data"
      container_path = "/var/lib/postgresql/data"
      type           = "volume"
    },
    {
      host_path      = "${path.module}/../healthchecks"
      container_path = "/healthchecks"
    }
  ]
  healthcheck = {
    test     = ["/healthchecks/postgres.sh"]
    interval = "5s"
  }
}

# Vote Service - Instance 1
module "vote1" {
  source = "./deployment"

  container_name = "vote1"
  image_name     = "vote_app"
  build_context  = "${path.module}/../voting-services/vote"
  dockerfile     = "${path.module}/../voting-services/vote/Dockerfile"
  networks       = [docker_network.front-tier.name, docker_network.back-tier.name]
  depends_on     = [module.redis]
  healthcheck    = {
    test         = ["CMD", "curl", "-f", "http://localhost:5000"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 2
    start_period = "5s"
  }
}

# Vote Service - Instance 2
module "vote2" {
  source = "./deployment"

  container_name = "vote2"
  image_name     = "vote_app"
  build_context  = "${path.module}/../voting-services/vote"
  dockerfile     = "${path.module}/../voting-services/vote/Dockerfile"
  networks       = [docker_network.front-tier.name, docker_network.back-tier.name]
  depends_on     = [module.redis]
  healthcheck    = {
    test         = ["CMD", "curl", "-f", "http://localhost:5000"]
    interval     = "15s"
    timeout      = "5s"
    retries      = 2
    start_period = "5s"
  }
}

# Worker Service
module "worker" {
  source = "./deployment"

  container_name = "worker"
  image_name     = "worker_app"
  build_context  = "${path.module}/../voting-services/worker"
  dockerfile     = "${path.module}/../voting-services/worker/Dockerfile"
  networks       = [docker_network.back-tier.name]
  depends_on     = [module.redis, module.db]
}

# Result Service
module "result" {
  source = "./deployment"

  container_name = "result"
  image_name     = "result_app"
  build_context  = "${path.module}/../voting-services/result"
  dockerfile     = "${path.module}/../voting-services/result/Dockerfile"
  networks       = [docker_network.front-tier.name, docker_network.back-tier.name]
  depends_on     = [module.db]
  container_ports = [
    {
      internal = 80
      external = 5050
    },
    {
      internal = 9229
      external = 9229
    }
  ]
}

# Nginx Service
module "nginx" {
  source = "./deployment"

  container_name = "nginx"
  image_name     = "nginx_app"
  build_context  = "${path.module}/../voting-services/nginx"
  dockerfile     = "${path.module}/../voting-services/nginx/Dockerfile"
  networks       = [docker_network.front-tier.name]
  depends_on     = [module.vote1, module.vote2]
  container_ports = [
    {
      internal = 8000
      external = 8000
    }
  ]
}

# Seed Service
module "seed" {
  source = "./deployment"

  container_name = "seed"
  image_name     = "seed_app"
  build_context  = "${path.module}/../voting-services/seed-data"
  dockerfile     = "${path.module}/../voting-services/seed-data/Dockerfile"
  networks       = [docker_network.front-tier.name]
  depends_on     = [module.nginx]
  environment    = {
    TARGET_HOST = "nginx"
    TARGET_PORT = "8000"
  }
  restart = "no"
}

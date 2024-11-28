module "redis-leader-deployment" {
  source = "../deployment/"

  metadata_name   = "redis-leader"
  label_app       = "redis"
  label_tier      = "backend"
  container_name  = "leader"
  container_image = "docker.io/redis:6.0.5"
  container_port  = 6379
}

resource "kubernetes_deployment_v1" "deplt" {
  metadata {
    name = var.metadata_name
    labels = {
      App  = var.label_app
      Tier = var.label_tier
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        App = var.label_app
      }
    }
    template {
      metadata {
        labels = {
          App  = var.label_app
          Tier = var.label_tier
        }
      }
      spec {
        container {
          name  = var.container_name
          image = var.container_image
          resources {
            requests = var.resources_requests
          }
          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

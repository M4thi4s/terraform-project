output "gcloud_config" {
  value = {
    project_id = var.project_id
    region     = var.region
    zone       = var.zone
  }
  description = "GCloud Project ID, Region and Zone"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.mycluster.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.mycluster.endpoint
  description = "GKE Cluster Host"
}

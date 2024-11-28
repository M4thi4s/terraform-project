module "gke" {
  source     = "./gke"
  project_id = "terraform-project-a3"
  region     = "us-east1"
  zone       = "us-east1-b"
}

variable "gcp_region" {
  default = "europe-west1"
}

variable "gcp_zone" {
  default = "europe-west1-b"
}

provider "google" {
  credentials = "${file("account.json")}"
  project     = "ecommerce-253018"
  region      = var.gcp_region
}

data "google_compute_zones" "available" {
}

variable "cluster_name" {
  default = "wordpress-cluster"
}

#variable "kubernetes_version" {
#  default = "1.11"
#}

variable "username" {
}

variable "password" {
}

resource "google_container_cluster" "primary" {
  name = var.cluster_name
  location = data.google_compute_zones.available.names[0]

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  node_locations = [
    data.google_compute_zones.available.names[1],
  ]

  #min_master_version = var.kubernetes_version
  #node_version       = var.kubernetes_version

  master_auth {
    username = var.username
    password = var.password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name = var.cluster_name
  location = data.google_compute_zones.available.names[0]
  cluster = "${google_container_cluster.primary.name}"

  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "f1-micro"
    disk_size_gb = 10

    metadata = {
      disable-legacy-endpoints = "true"
    }

  oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "primary_zone" {
  value = google_container_cluster.primary.zone
}

output "additional_zones" {
  value = google_container_cluster.primary.additional_zones
}

output "endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "node_version" {
  value = google_container_cluster.primary.node_version
}

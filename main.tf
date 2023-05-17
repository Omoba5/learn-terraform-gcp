terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("..\\gcp-credential.json")

  project = "testing-387012"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "tf_subnet" {
  name          = "tf-subnetwork"
  ip_cidr_range = "10.128.10.0/24"
  region        = "us-central1"
  network = google_compute_network.vpc_network.name
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "n1-standard-1"
  tags         = ["web", "dev"]

# metadata = {
#     startup-script = "sudo apt-get update && sudo apt-get install nginx -y"
#   }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.tf_subnet.name
    access_config {
    }
  }
}

resource "google_compute_firewall" "rules" {
  name        = "tf-firewall-rule"
  network     = google_compute_network.vpc_network.name
  description = "Creates firewall rule targeting tagged instances for terraform infrastructure"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "22", "1000-2000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

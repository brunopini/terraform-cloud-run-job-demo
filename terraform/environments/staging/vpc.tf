resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-sbn-${var.region_short}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.name
}

resource "google_compute_firewall" "firewall_egress" {
  name    = "${var.project_id}-fwe-${var.region_short}-vpcegress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  destination_ranges = ["0.0.0.0/0"]

  direction = "EGRESS"
}

resource "google_compute_router" "router" {
  name    = "${var.project_id}-rtr-g-vpcrouter"
  region  = var.region
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat-${var.region_short}-sbnnat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

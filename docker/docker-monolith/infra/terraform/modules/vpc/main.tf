resource "google_compute_firewall" "firewall_ssh" {
  name        = "terraform-allow-ssh"
  description = "TF: Allow SSH from anywhere"
  network     = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.source_ranges
}

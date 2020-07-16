output "vpc_allowed_ssh_range" {
  value = google_compute_firewall.firewall_ssh.source_ranges
}

variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone for VM instance"
  default     = "europe-west1-b"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "docker-base"
}

variable app_instances_amount {
  description = "Amount of app instances to create"
  default     = 1
}

variable vpc_ssh_allowed_range {
  description = "A list of addresses to access via ssh"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

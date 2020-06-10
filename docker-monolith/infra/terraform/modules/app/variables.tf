variable public_key_path {
  description = "Path to the public key used to connect to instance"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for docker monolith app"
  default     = "docker-base"
}

variable "instances_amount" {
  description = "Amount of required instances of the app"
  default     = 1
}

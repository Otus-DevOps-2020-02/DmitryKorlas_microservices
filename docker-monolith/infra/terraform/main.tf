provider "google" {
  # provider version
  version = "2.15"
  project = var.project
  region  = var.region
}

module "app" {
  source           = "./modules/app"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  zone             = var.zone
  app_disk_image   = var.app_disk_image
}

module "vpc" {
  source        = "./modules/vpc"
  source_ranges = var.vpc_ssh_allowed_range
}

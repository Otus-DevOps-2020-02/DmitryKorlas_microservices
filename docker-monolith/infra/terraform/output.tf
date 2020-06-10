output "app_external_ip" {
  value = module.app.app_external_ip
}

output "vpc_allowed_ssh_range" {
  value = module.vpc.vpc_allowed_ssh_range
}

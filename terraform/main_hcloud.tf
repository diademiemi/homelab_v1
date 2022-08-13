variable "hcloud_token" {
  sensitive = true # Requires terraform >= 0.14
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_server_type" {
  default = "cpx11"
}

variable "hcloud_datacenter" {
  default = "nbg1-dc3"
}

resource "hcloud_ssh_key" "ssh_pub_key" {
  name        = "ssh_pub_key"
  public_key  = var.ssh_pub_key
}
resource "hcloud_server" "step_hcloud" {
  name        = "${var.step_hcloud_hostname}"
  image       = "ubuntu-20.04"
  server_type = "${var.hcloud_server_type}"
  datacenter  = "${var.hcloud_datacenter}"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  ssh_keys = [
    hcloud_ssh_key.ssh_pub_key.id
  ]

}
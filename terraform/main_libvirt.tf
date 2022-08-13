resource "libvirt_network" "k3snet" {
  name      = "k3snet"
  mode      = "bridge"
  bridge    = "br100"

  addresses = ["10.100.0.0/16"]
}

resource "libvirt_pool" "disks" {
  name = "disks"
  type = "dir"
  path = "/storage/disks"
}

variable "vlan102_gw" {
  default = "192.168.100.129"
}

variable "vlan102_dns" {
  default = "9.9.9.9"
}

resource "libvirt_volume" "ubuntu_20_04_volume" {
  name   = "ubuntu_20_04"
  pool   = libvirt_pool.disks.name
  source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  format = "qcow2"
}

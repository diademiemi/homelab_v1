terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

provider "libvirt" {
  # Forward this with:
  # nc -kl -c 'ssh truenas "nc -U /run/truenas_libvirt/libvirt-sock"' 127.0.0.1 5000
  uri = "qemu+tcp://localhost:5000/system"
}

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

data "template_file" "user_data" {
  template = file("${path.module}/files/cloud-init/cloud_init.cfg")
  count    = "${var.k3s_nodes}"
  vars = {
    hostname = "${lookup(var.k3s_hostnames, count.index)}"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/files/cloud-init/network_config.cfg")
  count    = "${var.k3s_nodes}"
  vars     = {
    vlan102_ip     = "${lookup(var.k3s_vlan102_ips, count.index)}"
    k3snet_ip      = "${lookup(var.k3s_k3snet_ips, count.index)}"
    k3s_vlan102_gw = "192.168.100.129"
    k3s_dns        = "9.9.9.9"
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count          = "${var.k3s_nodes}"
  name           = format("%s-%s", lookup(var.k3s_hostnames, count.index), "init.iso")
  user_data      = element(data.template_file.user_data.*.rendered, count.index)
  network_config = element(data.template_file.network_config.*.rendered, count.index)
  pool           = libvirt_pool.disks.name
}

resource "libvirt_volume" "ubuntu_20_04_volume" {
  name   = "ubuntu_20_04"
  pool   = libvirt_pool.disks.name
  source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "k3s-disk" {
  name           = "${lookup(var.k3s_hostnames, count.index)}"
  pool           = libvirt_pool.disks.name
  base_volume_id = libvirt_volume.ubuntu_20_04_volume.id
  size           = "60000000000"
  count          = "${var.k3s_nodes}"
}

variable "k3s_nodes" {
  default = 4
}

variable "k3s_hostnames" {
  default = {
    "0" = "k3s-master",
    "1" = "k3s-worker01",
    "2" = "k3s-worker02",
    "3" = "k3s-worker03",
  }
}

variable "k3s_vlan102_ips" {
  default = {
    "0" = "192.168.100.150/26",
    "1" = "192.168.100.151/26",
    "2" = "192.168.100.152/26",
    "3" = "192.168.100.153/26",
  }
}

variable "k3s_k3snet_ips" {
  default = {
    "0" = "10.100.0.10/16",
    "1" = "10.100.0.11/16",
    "2" = "10.100.0.12/16",
    "3" = "10.100.0.13/16",
  }
}

resource "libvirt_domain" "k3s" {
  count  = "${var.k3s_nodes}"
  name   = "${lookup(var.k3s_hostnames, count.index)}"
  arch   = "x86_64"
  cpu {
    mode = "host-passthrough"
  }
  vcpu   = 6
  memory = 6144

  cloudinit = element(libvirt_cloudinit_disk.commoninit.*.id, count.index)

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  disk {
    volume_id = element(libvirt_volume.k3s-disk.*.id, count.index)
    scsi      = "true"
  }

  network_interface {
    network_id     = libvirt_network.k3snet.id
    wait_for_lease = false
  }

  network_interface {
    macvtap        = "vlan102"
    wait_for_lease = false
  }

}
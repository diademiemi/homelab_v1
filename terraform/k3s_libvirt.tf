resource "libvirt_volume" "k3s-disk" {
  name           = "${lookup(var.k3s_hostnames, count.index)}"
  pool           = libvirt_pool.disks.name
  base_volume_id = libvirt_volume.ubuntu_20_04_volume.id
  size           = "60000000000"
  count          = "${var.k3s_nodes}"
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

  cloudinit = element(libvirt_cloudinit_disk.k3s_commoninit.*.id, count.index)

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

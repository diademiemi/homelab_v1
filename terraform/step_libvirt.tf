resource "libvirt_volume" "step-disk" {
  name           = "${var.step_hostname}"
  pool           = libvirt_pool.disks.name
  base_volume_id = libvirt_volume.ubuntu_20_04_volume.id
  size           = "30000000000"
}

resource "libvirt_domain" "step" {
  name   = "${var.step_hostname}"
  arch   = "x86_64"
  cpu {
    mode = "host-passthrough"
  }
  vcpu   = 2
  memory = 2048

  cloudinit = libvirt_cloudinit_disk.step_commoninit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  disk {
    volume_id = libvirt_volume.step-disk.id
    scsi      = "true"
  }

  network_interface {
    macvtap        = "vlan102"
    wait_for_lease = false
  }

}

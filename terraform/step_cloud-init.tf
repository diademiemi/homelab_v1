data "template_file" "step_user_data" {
  template = file("${path.module}/cloud-init/cloud_init.cfg")
  vars = {
    hostname   = "${var.step_hostname}"
    ssh_pub_key = "${var.ssh_pub_key}"
  }
}

data "template_file" "step_network_config" {
  template = file("${path.module}/cloud-init/step_network_config.cfg")
  vars     = {
    vlan102_ip     = "${var.step_ip}"
    vlan102_gw     = "${var.vlan102_gw}"
    vlan102_dns    = "${var.vlan102_dns}"
  }
}

resource "libvirt_cloudinit_disk" "step_commoninit" {
  name           = format("%s-%s", var.step_hostname, "init.iso")
  user_data      = data.template_file.step_user_data.rendered
  network_config = data.template_file.step_network_config.rendered
  pool           = libvirt_pool.disks.name
}

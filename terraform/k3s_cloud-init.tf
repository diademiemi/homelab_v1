data "template_file" "k3s_user_data" {
  template = file("${path.module}/cloud-init/cloud_init.cfg")
  count    = "${var.k3s_nodes}"
  vars = {
    hostname    = "${lookup(var.k3s_hostnames, count.index)}"
    ssh_pub_key = "${var.ssh_pub_key}"
  }
}

data "template_file" "k3s_network_config" {
  template = file("${path.module}/cloud-init/k3s_network_config.cfg")
  count    = "${var.k3s_nodes}"
  vars     = {
    vlan102_ip     = "${lookup(var.k3s_vlan102_ips, count.index)}"
    vlan102_gw     = "${var.vlan102_gw}"
    vlan102_dns    = "${var.vlan102_dns}"
    k3snet_ip      = "${lookup(var.k3s_k3snet_ips, count.index)}"
  }
}

resource "libvirt_cloudinit_disk" "k3s_commoninit" {
  count          = "${var.k3s_nodes}"
  name           = format("%s-%s", lookup(var.k3s_hostnames, count.index), "init.iso")
  user_data      = element(data.template_file.k3s_user_data.*.rendered, count.index)
  network_config = element(data.template_file.k3s_network_config.*.rendered, count.index)
  pool           = libvirt_pool.disks.name
}

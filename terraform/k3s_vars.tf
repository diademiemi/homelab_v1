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

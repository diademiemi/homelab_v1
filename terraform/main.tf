terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
    }
  }
}

provider "libvirt" {
  # Forward this with:
  # nc -kl -c 'ssh truenas "nc -U /run/truenas_libvirt/libvirt-sock"' 127.0.0.1 5000
  uri = "qemu+tcp://localhost:5000/system"
}

variable "ssh_pub_key" {
  sensitive = true
}

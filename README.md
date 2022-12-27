# ARCHIVED
This was the first homelab setup I did where I used DevOps tooling to achieve my goals. 
I am trying something new, and archiving this repository in favour of [diademiemi/homelab_v2](https://github.com/diademiemi/homelab_v2)!  

# Homelab setup from diademiemi

This is my homelab setup.  
The VMs are running on TrueNAS Scale with libvirt. A Hetzner VPS is also used to proxy traffic from a public IP to the cluster over a Wireguard VPN tunnel.
TrueNAS Scale also acts as an NFS and iSCSI server for persistent storage on the Kubernetes containers.  

## Terraform

The VMs are deployed with Terraform on libvirt alongside a VPS on Hetzner Cloud.

### Libvirt
To connect to TrueNAS's libvirt socket, run:  
`nc -kl -c 'ssh truenas "nc -U /run/truenas_libvirt/libvirt-sock"' 127.0.0.1 5000`  
###### Replace truenas with your truenas host

Make sure the following options are set in `/etc/libvirt/qemu.conf` on TrueNAS and restart libvirt (`systemctl restart libvirt`)  
```bash
# Not setting this will prevent Terraform from creating VM images.
security_driver = "none"

user = "root" # Or other user you are logging in as
group = "kvm"
```

The libvirt socket will then be accessible at [qemu+tcp://localhost:5000/system](qemu+tcp://localhost:5000/system).  

You can then view the changes that will be made with `terraform plan` and create them with `terraform apply` to roll out the VMs. Running `terraform destroy` will destroy the resources.  

The VMs will have an IP on an internal network `10.100.0.0/16` to access NFS and iSCSI. They will also get an IP in the range `192.168.100.150/25-192.168.100.153/25` which is accessible on VLAN 102 on the network.  

The VMs that are deployed will have the hostnames:  
- `k3s-master`  
- `k3s-worker01`  
- `k3s-worker02`  
- `k3s-worker03`  
- `step01`

### Hetzner
A stepping stone / reverse proxy server is also deploye on Hetzner. This server proxies traffic from a public IP to the cluster through a Wireguard VPN.  
Create a project on hetzner and get an API token. Create a file `terraform/secrets.auto.tfvars` with the content:  
```tfvars
hcloud_token = "xxx"
ssh_pub_key = "Your SSH public key" # Used to log in
```

A VPS named `step02` will be created on Hetzner cloud.

## Ansible

Ansible uses inventory.ini to connect to the created virtual machines and VPS to:  
- Set the root password
- Update Cloudflare DNS records
- Create Wireguard VPN tunnel between homelab VMs and VPS
- Generate Wireguard configs for clients, if given, to access LAN from the internet
- Set up Nginx traffic forwarder / proxy
- Update packages
- Install K3S
- Set up a Kubernetes cluster
- Deploy Kubernetes
  - Ingress
  - cert-manager
  - Storage
    - NFS
    - iSCSI
  - Various charts

Files in the `files/` directory are read as templates. This allows me to insert variables in a Jinja2 syntax. This way I can store variables like API keys, domain names and other secrets in Ansible Vault while still sharing my Kubernetes definitions for others to see.  

## Kubernetes

MetalLB will be used as a loadbalancer. Traefik and AdGuard Home will make use of this.

An instance of Traefik will be deployed for public-facing services. This will be available at `192.168.100.160`, I port forward this IP on ports 80/tcp and 443/tcp. Another will be deployed at `192.168.100.161` for services that should only be accessible on LAN.  
AdGuard Home will listen on port 53/udp on `192.168.100.163`.  

These IPs are configurable in [group_vars/all/main.yml](group_vars/all/main.yml)  

## Variables
Most variables are set in [group_vars/all/main.yml](group_vars/all/main.yml) and [host_vars/localhost/main.yml](host_vars/localhost/main.yml).  
I have encrypted my personal values with Ansible Vault and left them out of this repository.  

In `host_vars/localhost/main.yml`, change `letsencrypt_directory` to `https://acme-v02.api.letsencrypt.org/directory` to get a trusted SSL certificate.  

## License

The files used to deploy my homelab are licensed under the [MIT License](./LICENSE).  
I encourage you to take inspiration from my setup and learn wonderful tools like Ansible, Terraform and Kubernetes.

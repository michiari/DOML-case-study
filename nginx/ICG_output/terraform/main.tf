

terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  insecure    = true
}

# Retrieve data
data "openstack_networking_network_v2" "external" {
  name = "external"
}


# Create virtual machine
resource "openstack_compute_instance_v2" "vm1" {
  name        = "concrete_vm"
  image_name  = "ubuntu-20.04.3"
  flavor_name = "small"
  key_pair    = openstack_compute_keypair_v2.ssh_key.name
  network { 
    port = openstack_networking_port_v2.net1_networking_port.id
    
  }
}

# Create floating ip
resource "openstack_networking_floatingip_v2" "vm1_floating_ip" {
  pool = "external"
  # fixed_ip = ""
}

# Attach floating ip to instance
resource "openstack_compute_floatingip_associate_v2" "vm1_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.vm1_floating_ip.address
  instance_id = openstack_compute_instance_v2.vm1.id
}

# Router interface configuration

resource "openstack_networking_router_interface_v2" "net1_router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.net1_subnet.id
}


## Network

# Create Network
resource "openstack_networking_network_v2" "ext_net" {
  name = "nginx_net"
}

# Subnet
resource "openstack_networking_subnet_v2" "net1_subnet" {
  name            = "net1_subnet"
  network_id      = openstack_networking_network_v2.ext_net.id
  cidr            = "10.0.0.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.8.4"]
}
# Attach networking port
resource "openstack_networking_port_v2" "net1_networking_port" {
  name           = "nginx_net"
  network_id     = openstack_networking_network_v2.ext_net.id
  admin_state_up = true
  security_group_ids = [
  openstack_compute_secgroup_v2.icmp.id,
  openstack_compute_secgroup_v2.http.id,
  openstack_compute_secgroup_v2.https.id,
  openstack_compute_secgroup_v2.ssh.id,
  
  ]
  fixed_ip {
   subnet_id = openstack_networking_subnet_v2.net1_subnet.id
  }
}



# Create router
resource "openstack_networking_router_v2" "router" { ## 1router, not parametric
  name                = "router"
  external_network_id = data.openstack_networking_network_v2.external.id    #External network id
}



# Create ssh keys
resource "openstack_compute_keypair_v2" "ssh_key" {
  name       = "vm2user"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}



# CREATING SECURITY_GROUP
  
resource "openstack_compute_secgroup_v2" "icmp" {
  name        = "icmp"
  description  = "Security group rule for port -1"
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}
 
resource "openstack_compute_secgroup_v2" "http" {
  name        = "http"
  description  = "Security group rule for port 80"
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
 
resource "openstack_compute_secgroup_v2" "https" {
  name        = "https"
  description  = "Security group rule for port 443"
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
 
resource "openstack_compute_secgroup_v2" "ssh" {
  name        = "ssh"
  description  = "Security group rule for port 22"
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}



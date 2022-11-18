

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
  name        = "concrete_vm1"
  image_name  = "ubuntu-20.04.3"
  flavor_name = "small-centos"
  key_pair    = openstack_compute_keypair_v2.ssh_key.name
  network { 
    port = openstack_networking_port_v2.subnet1_networking_port.id
    
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

resource "openstack_networking_router_interface_v2" "subnet1_router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet1_subnet.id
}



# Create virtual machine
resource "openstack_compute_instance_v2" "vm2" {
  name        = "concrete_vm2"
  image_name  = "ubuntu-20.04.3"
  flavor_name = "small-centos"
  key_pair    = openstack_compute_keypair_v2.ssh_key.name
  network { 
    port = openstack_networking_port_v2.subnet1_networking_port.id
    
  }
}

# Create floating ip
resource "openstack_networking_floatingip_v2" "vm2_floating_ip" {
  pool = "external"
  # fixed_ip = ""
}

# Attach floating ip to instance
resource "openstack_compute_floatingip_associate_v2" "vm2_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.vm2_floating_ip.address
  instance_id = openstack_compute_instance_v2.vm2.id
}

# Router interface configuration

resource "openstack_networking_router_interface_v2" "subnet1_router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet1_subnet.id
}


## Network

# Create Network
resource "openstack_networking_network_v2" "net1" {
  name = "concrete_net"
}

# Subnet
resource "openstack_networking_subnet_v2" "subnet1_subnet" {
  name            = "subnet1_subnet"
  network_id      = openstack_networking_network_v2.net1.id
  cidr            = "10.100.1.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.8.4"]
}
# Attach networking port
resource "openstack_networking_port_v2" "subnet1_networking_port" {
  name           = "concrete_net"
  network_id     = openstack_networking_network_v2.net1.id
  admin_state_up = true
  security_group_ids = [
  
  ]
  fixed_ip {
   subnet_id = openstack_networking_subnet_v2.subnet1_subnet.id
  }
}



# Create router
resource "openstack_networking_router_v2" "router" { ## 1router, not parametric
  name                = "router"
  external_network_id = data.openstack_networking_network_v2.external.id    #External network id
}



# Create ssh keys
resource "openstack_compute_keypair_v2" "ssh_key" {
  name       = "myuser"
  public_key = "local path to ssh key"
}


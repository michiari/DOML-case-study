

output "instance_server_public_key_ssh_key" {
  value = openstack_compute_keypair_v2.ssh_key.public_key
}

output "instance_server_private_key_ssh_key" {
  value = openstack_compute_keypair_v2.ssh_key.private_key
}

output "instance_ip_vm1" {
  value = openstack_compute_floatingip_associate_v2.vm1_floating_ip_association.floating_ip
}


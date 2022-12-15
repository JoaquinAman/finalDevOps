output "private_ip_addresses" {
  value       = concat(azurerm_network_interface.joaquin-private-nic-ansible.*.private_ip_address, azurerm_network_interface.joaquin-public-nic.*.private_ip_address)
}

output "public_ip_address" {
  value       = data.azurerm_public_ip.public_ip.ip_address
}

output "public_ip_address_ansible" {
  value       = data.azurerm_public_ip.public_ip_ansible.ip_address
}

output "ansible-ssh-command" {
  value       = "ssh -i ./keys/joaquin-ansible-key joaquin@${data.azurerm_public_ip.public_ip_ansible.ip_address}"
}
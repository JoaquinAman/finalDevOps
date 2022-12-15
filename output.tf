output "private_ip_addresses" {
  description = "private IPs."
  value       = concat(azurerm_network_interface.joaquin-private-nic-ansible.*.private_ip_address, azurerm_network_interface.joaquin-public-nic.*.private_ip_address)
}

output "public_ip_address" {
  description = "public IP address for public vm."
  value       = data.azurerm_public_ip.public_ip[*].ip_address
}

output "public_ip_address_ansible" {
  description = "public IP address for private vm."
  value       = data.azurerm_public_ip.public_ip_ansible[*].ip_address
}

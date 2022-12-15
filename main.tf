resource "azurerm_resource_group" "joaquin-rg" {
  name     = "joaquin-rg"
  location = "eastus"

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_virtual_network" "joaquin-vn" {
  name                = "joaquin-vn"
  address_space       = ["192.168.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.joaquin-rg.name

  lifecycle {
    create_before_destroy = true
  }
}


resource "azurerm_public_ip" "public_ip" {
  name                = "joaquin-public-ip"
  resource_group_name = azurerm_resource_group.joaquin-rg.name
  location            = azurerm_resource_group.joaquin-rg.location
  allocation_method   = "Static"
}

data "azurerm_public_ip" "public_ip" {
  name                = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.joaquin-rg.name

  depends_on = [azurerm_linux_virtual_machine.public_vm]
}


resource "azurerm_subnet" "joaquin-sn-public" {
  name                 = "joaquin-sn-public"
  resource_group_name  = azurerm_resource_group.joaquin-rg.name
  virtual_network_name = azurerm_virtual_network.joaquin-vn.name
  address_prefixes     = ["192.168.1.0/24"]
}


resource "azurerm_network_security_group" "joaquin-public-sg" {
  name                = "joaquin-public-sg"
  location            = azurerm_resource_group.joaquin-rg.location
  resource_group_name = azurerm_resource_group.joaquin-rg.name


  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "192.168.2.0/24"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "allow-web"
    description                = "allow-web"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet_network_security_group_association" "subnet_public" {
  subnet_id                 = azurerm_subnet.joaquin-sn-public.id
  network_security_group_id = azurerm_network_security_group.joaquin-public-sg.id
}


resource "azurerm_network_interface" "joaquin-public-nic" {
  name                = "joaquin-public-nic"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.joaquin-rg.name

  ip_configuration {
    name                          = "linux_subnet_public"
    subnet_id                     = azurerm_subnet.joaquin-sn-public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "public_vm" {
  name                  = "Linux-public-VM"
  resource_group_name   = azurerm_resource_group.joaquin-rg.name
  location              = "eastus"
  size                  = "Standard_B1s"
  admin_username        = "joaquin"
  network_interface_ids = [azurerm_network_interface.joaquin-public-nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "joaquin"
    public_key = file("./keys/joaquin-public-key.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


resource "azurerm_subnet" "joaquin-sn-private" {
  name                 = "joaquin-sn-private"
  resource_group_name  = azurerm_resource_group.joaquin-rg.name
  virtual_network_name = azurerm_virtual_network.joaquin-vn.name
  address_prefixes     = ["192.168.2.0/24"]

  lifecycle {
    create_before_destroy = true
  }
}


resource "azurerm_network_security_group" "subnet_private_nsg" {
  name                = "security_subnet_private_ngs"
  location            = azurerm_resource_group.joaquin-rg.location
  resource_group_name = azurerm_resource_group.joaquin-rg.name



  security_rule {
    name                       = "allow-ssh"
    description                = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "azurerm_subnet_network_security_group_association" "subnet_private" {
  subnet_id                 = azurerm_subnet.joaquin-sn-private.id
  network_security_group_id = azurerm_network_security_group.subnet_private_nsg.id
}


resource "azurerm_public_ip" "public_ip_ansible" {
  name                = "Public_IP_ANSIBLE"
  resource_group_name = azurerm_resource_group.joaquin-rg.name
  location            = azurerm_resource_group.joaquin-rg.location
  allocation_method   = "Static"

  lifecycle {
    create_before_destroy = true
  }
}

data "azurerm_public_ip" "public_ip_ansible" {
  name                = azurerm_public_ip.public_ip_ansible.name
  resource_group_name = azurerm_resource_group.joaquin-rg.name
}


resource "azurerm_network_interface" "joaquin-private-nic-ansible" {
  name                = "joaquin-private-nic-ansible"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.joaquin-rg.name

  ip_configuration {
    name                          = "linux_subnet_private"
    subnet_id                     = azurerm_subnet.joaquin-sn-private.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_ansible.id
  }
}



data "template_file" "joaquin-userdata" {
  template = file("./scripts/joaquin-userdata.cfg")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.joaquin-userdata.rendered
  }
}


resource "azurerm_linux_virtual_machine" "joaquin-private-vn" {
  name                = "joaquin-private-vn"
  resource_group_name = azurerm_resource_group.joaquin-rg.name
  location            = "eastus"
  size                = "Standard_B1s"
  admin_username      = "joaquin"

  network_interface_ids = [azurerm_network_interface.joaquin-private-nic-ansible.id]
  custom_data           = data.template_cloudinit_config.config.rendered

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }



  admin_ssh_key {
    username   = "joaquin"
    public_key = file("./keys/joaquin-ansible-key.pub")
  }


  connection {
    type        = "ssh"
    user        = "joaquin"
    host        = self.public_ip_address
    private_key = file("./keys/joaquin-ansible-key")
  }


  provisioner "file" {
    source      = "./keys/joaquin-public-key"
    destination = "/home/joaquin/.ssh/private-key-joaquin-public-vm"
  }


  provisioner "file" {
    source      = "./files/hello-world.html"
    destination = "/home/joaquin/hello-world.html"
  }


  provisioner "file" {
    source      = "./myplaybook.yml"
    destination = "/home/joaquin/myplaybook.yml"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/private-key-joaquin-public-vm",
      "cloud-init status --wait",
      "ansible-playbook -i joaquin@${azurerm_network_interface.joaquin-public-nic.private_ip_address}, --private-key ~/.ssh/private-key-joaquin-public-vm myplaybook.yml -u joaquin --become --ssh-common-args='-o StrictHostKeyChecking=no'"
    ]
  }
}

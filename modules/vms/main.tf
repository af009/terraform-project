# Create network interface vm1
resource "azurerm_network_interface" "nic-vms" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Virtual Machine (VMS)
resource "azurerm_linux_virtual_machine" "vms" {
  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  zone                            = var.vm_zone
  network_interface_ids = [
    azurerm_network_interface.nic-vms.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }


}


# NIC & NSG (association) - VMS
resource "azurerm_network_interface_security_group_association" "nsg-nic-vms" {
  network_interface_id      = azurerm_network_interface.nic-vms.id
  network_security_group_id = var.network_security_group_id
}

# NIC VMS & Nat rule association
resource "azurerm_network_interface_nat_rule_association" "nic_natrule_association-vms" {
  ip_configuration_name = azurerm_network_interface.nic-vms.ip_configuration[0].name
  nat_rule_id           = var.nat_rule_id
  network_interface_id  = azurerm_network_interface.nic-vms.id
}

# Backend Pool and NIC vm1 - association
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_association-vms" {
  backend_address_pool_id = var.backend_address_pool_id
  ip_configuration_name   = azurerm_network_interface.nic-vms.ip_configuration[0].name
  network_interface_id    = azurerm_network_interface.nic-vms.id
}


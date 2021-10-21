

# Create a NIC for the VMS

resource "azurerm_network_interface" "nic-vms" {
  name                = var.nic-name
  location            = var.location
  resource_group_name = var.resource_group_name


  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
#resource "azurerm_network_interface_security_group_association" "association"{
#  network_interface_id = azurerm_network_interface.nic-vms.id
#  network_security_group_id = var.network_security_group_id
#}

# Create NAT gateway
resource "azurerm_nat_gateway" "nat_gatewey" {
  location            = var.location
  name                = "nat_gatewey_test1"
  resource_group_name = var.resource_group_name
  #availability_zone   = "none"
  idle_timeout_in_minutes = 15

}

# Public ip association
resource "azurerm_nat_gateway_public_ip_association" "nat-ip-association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gatewey.id
  public_ip_address_id = var.public_ip_address_id
}

# Public prefix association
#resource "azurerm_nat_gateway_public_ip_prefix_association" "nat-ip-prefix-association" {
#  nat_gateway_id      = azurerm_nat_gateway.nat_gatewey.id
#  public_ip_prefix_id = var.public_ip_prefix_id
#}

resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_pool" {
  network_interface_id    = azurerm_network_interface.nic-vms.id
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = var.backend_address_pool_id
}

# Crate a nat rule for VM 1
resource "azurerm_lb_nat_rule" "nat-rule-vm1" {
  backend_port                   = var.back_front_port
  frontend_ip_configuration_name = var.config_name
  frontend_port                  = var.back_front_port #221
  loadbalancer_id                = var.loadbalancer_id
  name                           = var.nat_rule_name
  protocol                       = "Tcp"
  resource_group_name            = var.resource_group_name
  enable_tcp_reset = true
  
}

# Create association to target specific vm
resource "azurerm_network_interface_nat_rule_association" "nic_nat_association" {
  network_interface_id  = azurerm_network_interface.nic-vms.id
  ip_configuration_name = "testconfiguration1"
  nat_rule_id           = azurerm_lb_nat_rule.nat-rule-vm1.id
}

# Create Load Balancer



# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "vms" {
  name                            = var.vm-name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm-size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  #zone = "1"

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

  # Remote provisioner added to automate some commands
 /*
  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = var.host_ip

    }

    inline = [
      "sudo apt update && sudo apt install npm -y && sudo npm i -g n && sudo n 12",

      "git clone https://github.com/af009/bootcamp-app.git && cd bootcamp-app && sudo npm install"

    ]
  }
 */
  #depends_on = [azurerm_network_interface.nic-vms]
}



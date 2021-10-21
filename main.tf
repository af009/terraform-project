# Configure the Azure provider
provider "azurerm" {
  features {}
}
# Create Resource Group
resource "azurerm_resource_group" "rg-terraform-app" {
  name     = "bootcamp-terraform-test3"
  location = "westeurope"
}
# Create Virtual Network
resource "azurerm_virtual_network" "app-vnet" {
  name                = "app-vnet"
  address_space       = ["10.17.0.0/20"]
  location            = azurerm_resource_group.rg-terraform-app.location
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
}
# Create Public Subnet (APP)
resource "azurerm_subnet" "app-subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg-terraform-app.name
  virtual_network_name = azurerm_virtual_network.app-vnet.name
  address_prefixes     = ["10.17.0.0/23"]

}
# Create IP for the NAT_GATEWAY
resource "azurerm_public_ip" "nat_ip" {
  name                = "nat_gateway_ip"
  location            = azurerm_resource_group.rg-terraform-app.location
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Create public IP - Load Balancer
resource "azurerm_public_ip" "public_ip_lb" {
  name                = "public_ip_lb"
  location            = azurerm_resource_group.rg-terraform-app.location
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Create network interface vm1
resource "azurerm_network_interface" "nic-vm1" {
  name                = "nic-vim1"
  location            = azurerm_resource_group.rg-terraform-app.location
  resource_group_name = azurerm_resource_group.rg-terraform-app.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.app-subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.public_ip_lb.id
  }
}
# Create network interface vm2
resource "azurerm_network_interface" "nic-vm2" {
  name                = "nic-vm2"
  location            = azurerm_resource_group.rg-terraform-app.location
  resource_group_name = azurerm_resource_group.rg-terraform-app.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.app-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create Virtual Machine (VM1)
resource "azurerm_linux_virtual_machine" "vms-1" {
  name                            = "vm-1"
  resource_group_name             = azurerm_resource_group.rg-terraform-app.name
  location                        = var.location
  size                            = "Standard_B1ms"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  zone                            = "1"
  network_interface_ids = [
    azurerm_network_interface.nic-vm1.id
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
# Create Virtual Machine (VM2)
resource "azurerm_linux_virtual_machine" "vm-2" {
  name                            = "vm-2"
  resource_group_name             = azurerm_resource_group.rg-terraform-app.name
  location                        = var.location
  size                            = "Standard_B1ms"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  zone                            = "2"

  network_interface_ids = [
    azurerm_network_interface.nic-vm2.id
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

# NIC & NSG (association) - vm1
resource "azurerm_network_interface_security_group_association" "nsg-nic-vm1" {
  network_interface_id      = azurerm_network_interface.nic-vm1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# NIC & NSG (association) - vm2
resource "azurerm_network_interface_security_group_association" "nsg-nic-vm2" {
  network_interface_id      = azurerm_network_interface.nic-vm2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Getting my own IP for ssh connection
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

#Create Network Security Group
resource "azurerm_network_security_group" "nsg" {
  location            = var.location
  name                = "nsg-app"
  resource_group_name = azurerm_resource_group.rg-terraform-app.name

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "SSH"
    priority                   = 1001
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.myip.body)}/32"
    destination_address_prefix = "*"

  }
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "Port-8080"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    #destination_address_prefix = "${chomp(azurerm_public_ip.public_ip_lb.ip_address)}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    access                     = "Allow"
    direction                  = "Outbound"
    name                       = "sql"
    priority                   = 110
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # depends_on = [azurerm_public_ip.public-ip]
}

# Create NAT gateway
resource "azurerm_nat_gateway" "nat_gatewey" {
  location            = var.location
  name                = "nat_gatewey_test1"
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
  #availability_zone   = "none"
  idle_timeout_in_minutes = 15

}

# Public ip & Nat association
resource "azurerm_nat_gateway_public_ip_association" "nat-ip-association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gatewey.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}
# Subnet & Nat association
resource "azurerm_subnet_nat_gateway_association" "subnet_nat_association" {
  nat_gateway_id = azurerm_nat_gateway.nat_gatewey.id
  subnet_id      = azurerm_subnet.app-subnet.id
}
# NIC VM1 & Nat rule association
resource "azurerm_network_interface_nat_rule_association" "nic_natrule_association-vm1" {
  ip_configuration_name = azurerm_network_interface.nic-vm1.ip_configuration[0].name
  nat_rule_id           = azurerm_lb_nat_rule.nat_rule1.id
  network_interface_id  = azurerm_network_interface.nic-vm1.id

}
# NIC VM2 & Nat rule association
resource "azurerm_network_interface_nat_rule_association" "nic_natrule_association-vm2" {
  ip_configuration_name = azurerm_network_interface.nic-vm2.ip_configuration[0].name
  nat_rule_id           = azurerm_lb_nat_rule.nat_rule2.id
  network_interface_id  = azurerm_network_interface.nic-vm2.id
}

# Create a load balancer
resource "azurerm_lb" "load-balancer" {
  location            = var.location
  name                = "load-balancer"
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
  sku                 = "Standard"


  frontend_ip_configuration {
    name                 = "lb-public-ip-address"
    public_ip_address_id = azurerm_public_ip.public_ip_lb.id
    #subnet_id            = azurerm_subnet.app-subnet.id
    #availability_zone    = "Zone-Redundant"

  }
}
resource "azurerm_lb_probe" "health-probe" {
  loadbalancer_id     = azurerm_lb.load-balancer.id
  name                = "health-probe"
  protocol            = "HTTP"
  port                = 8080
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
  request_path = "/"
}
# Backend Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.load-balancer.id
  name            = "backend_pool"
}
# Backend Pool and NIC vm1 - association
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_association-vm1" {
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_configuration_name   = azurerm_network_interface.nic-vm1.ip_configuration[0].name
  network_interface_id    = azurerm_network_interface.nic-vm1.id
}
# Backend Pool and NIC vm2 - association
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_association-vm2" {
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_configuration_name   = azurerm_network_interface.nic-vm2.ip_configuration[0].name
  network_interface_id    = azurerm_network_interface.nic-vm2.id
}
# Create Load Balancer Rule
resource "azurerm_lb_rule" "lb_rule" {
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.load-balancer.frontend_ip_configuration[0].name
  frontend_port                  = 8080
  loadbalancer_id                = azurerm_lb.load-balancer.id
  name                           = "lb_rule"
  protocol                       = "tcp"
  resource_group_name            = azurerm_resource_group.rg-terraform-app.name
  enable_floating_ip             = false
  enable_tcp_reset               = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
}

# Create Nat Rule 1
resource "azurerm_lb_nat_rule" "nat_rule1" {
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.load-balancer.frontend_ip_configuration[0].name
  frontend_port                  = 221
  loadbalancer_id                = azurerm_lb.load-balancer.id
  name                           = "nat_rule1"
  protocol                       = "tcp"
  resource_group_name            = azurerm_resource_group.rg-terraform-app.name
  enable_floating_ip             = false
  enable_tcp_reset               = true

}
# Create Nat Rule 2
resource "azurerm_lb_nat_rule" "nat_rule2" {
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.load-balancer.frontend_ip_configuration[0].name
  frontend_port                  = 222
  loadbalancer_id                = azurerm_lb.load-balancer.id
  name                           = "nat_rule2"
  protocol                       = "tcp"
  resource_group_name            = azurerm_resource_group.rg-terraform-app.name
  enable_floating_ip             = false
  enable_tcp_reset               = true
}

module "postgresql" {
  source = "./modules/postgresql"
  local_ip = chomp(data.http.myip.body)
  PGUSERNAME = var.PGUSERNAME
  PGPASSWORD = var.PGPASSWORD
  location = var.location
  public_ip = azurerm_public_ip.public_ip_lb.ip_address
  resource_group_name = azurerm_resource_group.rg-terraform-app.name
}

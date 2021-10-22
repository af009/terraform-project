output "nic_id" {
  value = azurerm_network_interface.nic-vms.id
}
output "vm_id" {
  value = azurerm_linux_virtual_machine.vms.id
}

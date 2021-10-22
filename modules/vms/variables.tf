variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
  default = "westeurope"
}
variable "vm_name" {
  type = string
}
variable "vm_zone" {
  type = string
}
variable "nic_name" {
  type = string
}
#variable "nic_id" {
#  type = string
#}
variable "subnet_id" {
  type = any
}
variable "vm_size" {
  type = string
  default = "Standard_B1ms"
}
variable "admin_username" {
  type = string
}
variable "admin_password" {
  type = string
}
variable "network_security_group_id" {
  type = string
}
variable "nat_rule_id" {
  type = string
}
#variable "host_ip" {
#  type = any
#}
variable "public_ip_address_id" {
  type = any
}
#variable "public_ip_prefix_id" {
#  type = any
#}
#variable "nat_rule_name" {
#  type = string
#}
#variable "back_front_port" {
#  type = number
#}
#variable "loadbalancer_id" {
#  type = string
#}

#variable "config_name" {
#  type = string
#}
variable "backend_address_pool_id" {
  type = any
}

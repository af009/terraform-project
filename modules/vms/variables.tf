variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
  default = "westeurope"
}
variable "vm-name" {
  type = string
}
variable "nic-name" {
  type = string
}
variable "subnet_id" {
  type = any
}
variable "vm-size" {
  type = string
}
variable "admin_username" {
  type = string
}
variable "admin_password" {
  type = string
}
#variable "network_security_group_id" {
#  type = any
#}
#variable "host_ip" {
#  type = any
#}
variable "public_ip_address_id" {
  type = any
}
#variable "public_ip_prefix_id" {
#  type = any
#}
variable "nat_rule_name" {
  type = string
}
variable "back_front_port" {
  type = number
}
variable "loadbalancer_id" {
  type = string
}
variable "config_name" {
  type = string
}
variable "backend_address_pool_id" {
  type = any
}

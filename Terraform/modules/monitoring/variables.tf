variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "onprem_rg_name" {
  type = string
}

variable "azure_rg_name" {
  type = string
}

variable "onprem_vnet_address_space" {
  type = string
}

variable "azure_vnet_address_space" {
  type = string
}

variable "enable_vpn_gateway" {
  type    = bool
  default = true
}

variable "vpn_shared_key" {
  type      = string
  sensitive = true
}

variable "allowed_rdp_sources" {
  type    = list(string)
  default = []
}
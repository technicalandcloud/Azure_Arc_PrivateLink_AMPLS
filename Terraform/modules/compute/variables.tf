variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "rg_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bastion_subnet_id" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "arc_client_id" {
  type      = string
  sensitive = true
}

variable "arc_client_secret" {
  type      = string
  sensitive = true
}

variable "arc_tenant_id" {
  type = string
}

variable "arc_subscription_id" {
  type = string
}

variable "arc_rg_name" {
  type = string
}

variable "arc_pls_id" {
  type = string
}

variable "arc_pe_name" {
  type        = string
  description = "Nom du Private Endpoint Arc"
}

variable "enable_monitoring" {
  type    = bool
  default = false
}

variable "dcr_id" {
  type    = string
  default = ""
}

variable "dce_id" {
  type    = string
  default = ""
}
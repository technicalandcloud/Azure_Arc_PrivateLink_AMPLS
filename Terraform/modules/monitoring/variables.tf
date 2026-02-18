variable "name_prefix" {
  description = "Préfixe pour le nommage des ressources"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
}

variable "rg_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "log_retention_days" {
  description = "Durée de rétention des logs en jours"
  type        = number
  default     = 30
}

variable "azure_subnet_id" {
  description = "ID du subnet Azure pour le Private Endpoint"
  type        = string
}

variable "onprem_vnet_id" {
  description = "ID du VNet OnPrem pour les liens DNS"
  type        = string
}

variable "azure_vnet_id" {
  description = "ID du VNet Azure pour les liens DNS"
  type        = string
}
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "arc-lab"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "francecentral"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "arc_client_id" {
  description = "Service Principal Client ID for Azure Arc"
  type        = string
  sensitive   = true
}

variable "arc_client_secret" {
  description = "Service Principal Client Secret for Azure Arc"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "vm_admin_username" {
  description = "VM administrator username"
  type        = string
  default     = "arcadmin"
}

variable "vm_admin_password" {
  description = "VM administrator password (empty = auto-generated)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "onprem_vnet_address_space" {
  description = "On-premises VNet address range"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azure_vnet_address_space" {
  description = "Azure VNet address range"
  type        = string
  default     = "10.20.0.0/16"
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "allowed_rdp_source_addresses" {
  description = "Allowed source IP addresses for RDP"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log retention duration (days)"
  type        = number
  default     = 30
}

variable "enable_ampls" {
  description = "Enable Azure Monitor Private Link Scope"
  type        = bool
  default     = true
}
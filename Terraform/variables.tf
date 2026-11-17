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

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.arc_client_id))
    error_message = "arc_client_id must be a GUID (set TF_VAR_arc_client_id)."
  }
}

variable "arc_client_secret" {
  description = "Service Principal Client Secret for Azure Arc"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.arc_client_secret) > 0
    error_message = "arc_client_secret is empty (set TF_VAR_arc_client_secret)."
  }
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "tenant_id must be a GUID (set TF_VAR_tenant_id)."
  }
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a GUID (set TF_VAR_subscription_id)."
  }
}

variable "check_arc_sp_credentials" {
  description = "Validate the Arc onboarding Service Principal credentials at plan time (set to false to destroy the lab after the SP was deleted)"
  type        = bool
  default     = true
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
  default     = "Standard_D2as_v7"
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
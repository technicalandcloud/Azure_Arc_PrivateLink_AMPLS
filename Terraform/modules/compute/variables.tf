# ==================== NAMING & LOCATION ====================
variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

# ==================== RESOURCE GROUP ====================
variable "rg_name" {
  description = "Resource group name for VM"
  type        = string
}

# ==================== NETWORKING ====================
variable "subnet_id" {
  description = "Subnet ID for VM NIC"
  type        = string
}

variable "bastion_subnet_id" {
  description = "Subnet ID for Bastion"
  type        = string
}

# ==================== VM CONFIGURATION ====================
variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "VM admin username"
  type        = string
}

variable "admin_password" {
  description = "VM admin password"
  type        = string
  sensitive   = true
}

# ==================== AZURE ARC ====================
variable "arc_client_id" {
  description = "Service Principal ID for Arc onboarding (appId)"
  type        = string
  sensitive   = true
}

variable "arc_client_secret" {
  description = "Service Principal Secret for Arc onboarding (password)"
  type        = string
  sensitive   = true
}

variable "arc_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "arc_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "arc_rg_name" {
  description = "Resource group name for Arc registration (Azure RG)"
  type        = string
}

variable "arc_pls_id" {
  description = "Arc Private Link Scope ID"
  type        = string
}

variable "arc_pe_name" {
  description = "Arc Private Endpoint name"
  type        = string
}

# ==================== MONITORING ====================
variable "enable_monitoring" {
  description = "Enable Azure Monitor Agent"
  type        = bool
  default     = false
}

variable "dcr_id" {
  type    = string
  default = null
}

variable "dce_id" {
  type    = string
  default = null
}
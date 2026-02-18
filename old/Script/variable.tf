variable "admin_username" {
  description = "Username for the Windows VM"
  type        = string
  default     = "arcadmin"
}

variable "admin_password" {
  description = "Password for the Windows VM"
  type        = string
  sensitive   = true
  default     = "ArcP@ssword123!"
}

variable "client_id" {
  description = "Azure AD App Client ID used for onboarding to Azure Arc"
  type        = string
}

variable "client_secret" {
  description = "Azure AD App Client Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Active Directory Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

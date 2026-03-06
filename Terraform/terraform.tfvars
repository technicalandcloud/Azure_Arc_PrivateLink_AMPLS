project_name = "arc-lab"
environment  = "dev"
location     = "francecentral"

# ============================================
# AUTHENTIFICATION AZURE
# ============================================

# Create a Service Principal:
# az ad sp create-for-rbac --name "arc-lab-sp" --role "Contributor" --scopes "/subscriptions/VOTRE_SUB_ID"

tenant_id       = "" #Tenant ID
subscription_id = "" #Subscription ID
arc_client_id     = "" #Arc SP Client ID
arc_client_secret = "" #Arc SP Client Secret

# ============================================
# COMPUTE
# ============================================

vm_admin_username = "arcadmin"
vm_admin_password = ""  # keep empty for automatic generation (recommended)
vm_size           = "Standard_D2s_v3"

# ============================================
# NETWORKING
# ============================================

onprem_vnet_address_space = "10.10.0.0/16"
azure_vnet_address_space  = "10.20.0.0/16"

# VPN Gateway vs VNet Peering
# - true  = VPN Gateway (~150€/mois) - simulate connexion between on-premises and Azure
# - false = VNet Peering (gratuit) - sufficient for a lab
enable_vpn_gateway = true

# ============================================
# MONITORING
# ============================================

enable_ampls       = true  
log_retention_days = 30     

# ============================================
# TAGS
# ============================================

tags = {
  Owner       = "votre-nom"
  Purpose     = "Azure Arc Lab"
  CostCenter  = "lab"
  Environment = "dev"
}
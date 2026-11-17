# Preflight check of the Arc onboarding Service Principal.
#
# The SP credentials are only used inside the VM by the onboarding script, about
# 15 minutes into `terraform apply`. Reading the subscription with them here makes
# `terraform plan` fail within seconds instead, with the Entra ID error code:
#   AADSTS7000215 -> invalid secret (expired, revoked, or belongs to another SP)
#   AADSTS700016  -> unknown client ID (wrong app ID or wrong tenant)
#   AuthorizationFailed -> the SP has no Reader role on the subscription
#
# Disable it with `-var check_arc_sp_credentials=false`, e.g. to destroy the lab
# after the SP was deleted.
data "azurerm_subscription" "arc_sp_check" {
  provider = azurerm.arc_onboarding
}

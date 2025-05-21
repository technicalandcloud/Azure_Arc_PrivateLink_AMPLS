# Azure Arc Jumpstart with Private Link (Terraform)

This Terraform configuration deploys a full Azure Arc-enabled infrastructure scenario using **Azure Virtual Network Gateway connections** between simulated **on-premises** and **Azure** environments. It includes support for **Azure Arc Private Link**, **Windows VM onboarding**, and **secure remote access via Azure Bastion**.

---

## 📌 Features

- Dual virtual network setup (on-prem & Azure)
- VNet-to-VNet VPN gateway connections
- Azure Arc Private Link Scope & Private Endpoint
- Windows Server VM onboarding to Azure Arc
- Custom Script Extension for automatic registration
- Azure Bastion host for RDP access
- Private DNS zone configuration
- Network security rules

---



## ✅ Prerequisites

- Azure CLI
- Terraform installed locally
- A **Service Principal** with `Contributor` role on a **subscription**
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- Azure Subscription
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- An Azure AD App registration with:
  - `Client ID`
  - `Client Secret`
  - `Tenant ID`
  - `Subscription ID`
  - `Username for VM`
  - `Passord for VM`


---
### Quick SPN creation:

```
az login
subscriptionId=$(az account show --query id --output tsv)
az ad sp create-for-rbac -n "JumpstartArc" --role "Contributor" --scopes /subscriptions/$subscriptionId
```
---
## 🚀 Deployment with Terraform

Run the Terraform script by providing the following input variables:

- `client_id`
- `client_secret`
- `tenant_id`
- `subscription_id`
- `admin_username`
- `admin_password`
These identifiers are linked to the Main Service created earlier.

---
## 🧪 Test Result

Once the deployment and configuration are complete:

- ✅ The **Azure Arc** resource is successfully onboarded  
- 📦 The `Azure Monitor Agent (AMA)` extension is installed  
- 🔍 You can view logs **privately** through **AMPLS**  
- 🧠 Data collection and monitoring work securely via **Private Link**

![image](https://github.com/user-attachments/assets/934640df-03ad-411c-9d78-744e924b6ebd)



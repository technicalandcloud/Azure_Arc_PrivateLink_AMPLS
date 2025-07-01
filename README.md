# Azure Arc + AMPLS Sandbox (Private Environment)

This repository provides a complete sandbox environment to explore **Azure Arc** and **Azure Monitor Private Link Scope (AMPLS)** in a **fully private setup using Azure Private Link**.

> ℹ️ This project is based on the community work from [Azure Arc Jumpstart](https://github.com/microsoft/azure_arc).  
> The Terraform code has been adapted from Jumpstart deployments to build a private environment integrating Azure Arc, AMPLS, and Private Link.

---

## 🎯 Purpose

The goal is to understand and test:

- Hybrid machine onboarding with **Azure Arc**
- How **AMPLS** works in a private network
- DNS resolution via **Private DNS Zones**

![image](https://github.com/user-attachments/assets/5207efe9-5d78-4bd6-96ec-093443f87a7a)


> ⚠️ This environment is intended for **testing and learning purposes only**. It **must not be used in production**.

---

## 📦 Repository Structure

- `Script/`: Contains both Terraform and PowerShell scripts.
---

## ✅ Prerequisites

- Azure CLI
- Terraform installed locally
- A **Service Principal** with `Contributor` role on a **subscription**
---
## ⚙️ Post-Deployment Steps

1. 🔗 Launch `monitor-setup-post.ps1`
2. 🛠️ Deploy the Terraform configuration
3. 💻 Connect to the deployed VM once it's ready
4. 🧭 Verify that the VM is onboarded to Azure Arc
5. 🎯 Launch the final script: `monitor-setup-pre.ps1`
6. 📘 Assign a Data Collection Rule (DCR) to the Azure Arc-enabled machine
7. 🎯 verify if AMA is Install
8. ✅ Done!

---

# ✔ Service Principal Setup

```powershell
# Sign in to Azure
az login

# Retrieve the subscription ID
$subId = az account show --query id -o tsv

# Create the service principal
$sp = az ad sp create-for-rbac `
    --name "JumpstartArc" `
    --role "Contributor" `
    --scopes "/subscriptions/$subId" `
    --output json | ConvertFrom-Json
# Manually construct the spn.json file
$spn = [PSCustomObject]@{
    clientId       = $sp.appId
    clientSecret   = $sp.password
    subscriptionId = $subId
    tenantId       = $sp.tenant
}

# Save as a JSON file
$spn | ConvertTo-Json -Depth 10 | Out-File -FilePath "spn.json" -Encoding utf8
```

Then load the credentials:
```powershell
$spn = Get-Content ./spn.json | ConvertFrom-Json

# ARM_* = used by Terraform provider
$env:ARM_CLIENT_ID       = $spn.clientId
$env:ARM_CLIENT_SECRET   = $spn.clientSecret
$env:ARM_SUBSCRIPTION_ID = $spn.subscriptionId
$env:ARM_TENANT_ID       = $spn.tenantId

# TF_VAR_* = used by Terraform variable injection
$env:TF_VAR_client_id       = $env:ARM_CLIENT_ID
$env:TF_VAR_client_secret   = $env:ARM_CLIENT_SECRET
$env:TF_VAR_subscription_id = $env:ARM_SUBSCRIPTION_ID
$env:TF_VAR_tenant_id       = $env:ARM_TENANT_ID

```
# 🚀 Deployment Steps

# Clone the repository
```
git clone https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS.git
cd Azure_Arc_PrivateLink_AMPLS/Script
```
#  Run the post-deployment setup (network, DNS, AMPLS)
```powershell
.\monitor-setup-post.ps1
```
# Deploy the infrastructure using Terraform
```terraform
terraform init
terraform apply -auto-approve
```
# Connect to the onboarded VM
Once the VM is created, use Azure Bastion connect and confirm that:

- The machine is onboarded to Azure Arc
- Network access is private-only

# Create Data Collection Rule 
GO to DCR and Create you DCR

![image](https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS/blob/main/asset/dcr1.png)

Select Resource ARC 

![image](https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS/blob/main/asset/dcr2.png)

Add source 

![image](https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS/blob/main/asset/dcr3.png)

Add LAW

![image](https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS/blob/main/asset/dcr4.png)

If all is ok AMA have been installed

![image](https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS/blob/main/asset/ama.png)

# Run the final configuration script
```powershell
.\monitor-setup-pre.ps1
```

✅ Post-Deployment Checks
---
After a few minutes:

✅ The Azure Arc machine appears in Azure

📦 The Azure Monitor Agent (AMA) extension is installed

🔐 Data flows privately through AMPLS

🧠 You can query logs in Log Analytics

## 🧪 Test Result

Once the deployment and configuration are complete:

- ✅ The **Azure Arc** resource is successfully onboarded  
- 📦 The `Azure Monitor Agent (AMA)` extension is installed  
- 🔍 You can view logs **privately** through **AMPLS**  
- 🧠 Data collection and monitoring work securely via **Private Link**

![image](https://github.com/user-attachments/assets/934640df-03ad-411c-9d78-744e924b6ebd)

🧹 Cleanup / Destruction
---
When using `terraform destroy`, you may encounter issues related to the Azure Arc onboarding process:

1. ❗ **Hybrid Machine resource not deleted**
   - Even after destroying the VM, the associated `Microsoft.HybridCompute/machines/<vm-name>` resource may still exist.
   - This resource must be deleted manually via Azure CLI:

     ```bash
     az resource delete \
       --ids "/subscriptions/<your-subscription-id>/resourceGroups/Arc-Azure-RG/providers/Microsoft.HybridCompute/machines/<vm-name>"
     ```

2. ❗ **Manual deletion of resource groups may be required**
   - In some cases, Terraform may be unable to delete the resource group due to lingering Arc-related resources (e.g., extensions, hybrid compute registrations).
   - You can manually delete the resource groups from the [Azure Portal](https://portal.azure.com) or use the CLI:

     ```bash
     az group delete --name Arc-Azure-RG --yes --no-wait
     az group delete --name Arc-OnPrem-RG --yes --no-wait
     ```

🔐 Use this option with caution, especially in production environments.

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

- `Terraform/`: Terraform scripts to deploy the partial environment.
- `Powershell/`: Powershell scripts to deploy the partial environment.
- `privatelink/artifacts/`: Supporting files (scripts, configurations, etc.)

---

## ✅ Prerequisites

- Azure CLI
- Terraform installed locally
- A **Service Principal** with `Contributor` role on a **subscription**
---
### Quick SPN creation:

```
az login
subscriptionId=$(az account show --query id --output tsv)
az ad sp create-for-rbac -n "JumpstartArc" --role "Contributor" --scopes /subscriptions/$subscriptionId
```
---
## 🚀 Deployment with Terraform


```bash
git clone https://github.com/technicalandcloud/Azure_Arc_PrivateLink_AMPLS.git
cd Azure_Arc_PrivateLink_AMPLS/Script

# Set up environment variables (SPN)
$env:ARM_CLIENT_ID = "xxxx"
$env:ARM_CLIENT_SECRET = "yyyy"
```

---
## ⚙️ Post-Deployment Steps

1. 🔗 Launch `monitor-setup-post.ps1`
2. 🛠️ Deploy the Terraform configuration
3. 💻 Connect to the deployed VM once it's ready
4. 🧭 Verify that the VM is onboarded to Azure Arc
5. 📘 Assign a Data Collection Rule (DCR) to the Azure Arc-enabled machine
6. 🎯 Launch the final script: `monitor-setup-pre.ps1`
7. ✅ Done!

---

## 🧪 Test Result

Once the deployment and configuration are complete:

- ✅ The **Azure Arc** resource is successfully onboarded  
- 📦 The `Azure Monitor Agent (AMA)` extension is installed  
- 🔍 You can view logs **privately** through **AMPLS**  
- 🧠 Data collection and monitoring work securely via **Private Link**

![image](https://github.com/user-attachments/assets/934640df-03ad-411c-9d78-744e924b6ebd)



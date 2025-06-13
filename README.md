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

Run the Terraform script by providing the following input variables:

- `client_id`
- `client_secret`
- `tenant_id`
- `subscription_id`
- `admin_username`
- `admin_password`
These identifiers are linked to the Main Service created earlier.

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

⏱️ After a few minutes:

- ✅ The **Azure Arc** resource will appear in the Azure portal  
- 📦 The `Azure Monitor Agent (AMA)` extension will be applied automatically  
- 🔐 Logs will be collected **privately** via **AMPLS**

![image](https://github.com/user-attachments/assets/2dbe7366-be7e-404e-af13-cd8d52a78f97)

![image](https://github.com/user-attachments/assets/cbc32083-6e79-4cb0-bc39-ee25c89abc0c)

![image](https://github.com/user-attachments/assets/1b67babf-aec9-4592-86f5-29c1b1534591)

---
## 🧪 Test Result

Once the deployment and configuration are complete:

- ✅ The **Azure Arc** resource is successfully onboarded  
- 📦 The `Azure Monitor Agent (AMA)` extension is installed  
- 🔍 You can view logs **privately** through **AMPLS**  
- 🧠 Data collection and monitoring work securely via **Private Link**

![image](https://github.com/user-attachments/assets/934640df-03ad-411c-9d78-744e924b6ebd)



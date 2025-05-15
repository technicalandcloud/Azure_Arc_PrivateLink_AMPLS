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

> ⚠️ This environment is intended for **testing and learning purposes only**. It **must not be used in production**.

---

## 📦 Repository Structure

- `Terraform/`: Terraform scripts to deploy the full environment.
- `privatelink/artifacts/`: Supporting files (scripts, configurations, etc.)

---

## ✅ Prerequisites

- Azure CLI
- Terraform installed locally
- A **Service Principal** with `Contributor` role on a **subscription**

### Quick SPN creation:

```bash
az login
subscriptionId=$(az account show --query id --output tsv)
az ad sp create-for-rbac -n "JumpstartArc" --role "Contributor" --scopes /subscriptions/$subscriptionId

## ⚙️ Post-Deployment Steps

After the Terraform deployment completes:

1. 🔗 Link the **Private Endpoint** of the `Data Collection Endpoint (DCE)` to your **AMPLS**
2. 🧾 Verify that the **Private DNS Zone** contains the correct records
3. 💻 Connect to the deployed VM using **Azure Bastion**
4. ▶️ Let the embedded **PowerShell** script run automatically

---

⏱️ After a few minutes:

- ✅ The **Azure Arc** resource will appear in the Azure portal  
- 📦 The `Azure Monitor Agent (AMA)` extension will be applied automatically  
- 🔐 Logs will be collected **privately** via **AMPLS**


![image](https://github.com/user-attachments/assets/f70306a7-60be-4a6b-9c7a-5be6deefd72e)
![image](https://github.com/user-attachments/assets/da91d339-ec74-4067-b21a-4dbc14fd4aaf)
![image](https://github.com/user-attachments/assets/5ffc5cc1-d3f9-469c-b596-5b0fd5aeab23)

## 🧪 Test Result

Once the deployment and configuration are complete:

- ✅ The **Azure Arc** resource is successfully onboarded  
- 📦 The `Azure Monitor Agent (AMA)` extension is installed  
- 🔍 You can view logs **privately** through **AMPLS**  
- 🧠 Data collection and monitoring work securely via **Private Link**


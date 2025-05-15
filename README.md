# Azure Arc + AMPLS Sandbox (Environnement privé)

Ce dépôt propose un environnement Sandbox complet pour explorer **Azure Arc** et **Azure Monitor Private Link Scope (AMPLS)**, en **mode full privé** via Private Link.

 ℹ️ Ce projet s’appuie sur le travail de la communauté [Azure Arc Jumpstart](https://github.com/microsoft/azure_arc).  
 Le code Terraform utilisé ici a été adapté à partir des déploiements proposés par Jumpstart pour créer un environnement privé basé sur Azure Arc, AMPLS et Private Link.

## 🎯 Objectif

Comprendre et tester :
- L'intégration d'une machine hybride avec **Azure Arc**
- Le fonctionnement d’un **AMPLS** en environnement privé
- Le routage DNS privé via Private DNS Zone

 ⚠️ Cet environnement est à usage de **test uniquement**. Il **ne doit pas être utilisé en production**.

---

## 📦 Structure du dépôt

- `Terraform/` : Scripts Terraform pour déployer l'environnement complet.
- `privatelink/artifacts/` : Fichiers de support (scripts, configurations, etc.)

---

## ✅ Prérequis

- Azure CLI
- Terraform installé localement
- Un **Service Principal** avec le rôle `Contributor` sur une **Subscription**

### Création rapide d’un SPN  :
az login
subscriptionId=$(az account show --query id --output tsv)
az ad sp create-for-rbac -n "JumpstartArc" --role "Contributor" --scopes /subscriptions/$subscriptionId

⚙️ Étapes post-déploiement
Une fois le déploiement veuillez bien à lié le private Endpont DCE sur le AMPLS & à vérifier la private dns zone est bien renseginé

![image](https://github.com/user-attachments/assets/f70306a7-60be-4a6b-9c7a-5be6deefd72e)
![image](https://github.com/user-attachments/assets/da91d339-ec74-4067-b21a-4dbc14fd4aaf)
![image](https://github.com/user-attachments/assets/5ffc5cc1-d3f9-469c-b596-5b0fd5aeab23)

Une fois terminé, vous pouvez lancer la VM depuis le Bastion et laisser executer le script Powerhsell, après quelques minutes, la resource Azure Arc remonte correctement la policy applique l'extension AMA et vous pouvez consulter les logs de manière privé grâce au AMPLS

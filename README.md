Ce repo à pour but d'aider les personnes qui souhaite utiliser un environnement SandBox pour comprendre le fonctionnement de Azure Arc Private & l' Azure Monitor Private link Scope, cet environnement est full privée.

Vous retrouverez dans le dossier "Terraform" le script permettant de déployer cet infrastrucutre, de test, attention cela n'est pas à mettre en production

Pour pouvoir executer ce script vous devez avoir une app registration de créér je vous invite donc à saisir cet commande pour une création simple est rapide:

az login
subscriptionId=$(az account show --query id --output tsv)
az ad sp create-for-rbac -n "JumpstartArc" --role "Contributor" --scopes /subscriptions/$subscriptionId

Une fois cela effectué, lors de l'execution du terraform il vous sera demandé d'insérer le Client ID, le Secret, le Tenant ID, le Subscription ID, le Admin UserName & le Password.

Une fois le script fini est pour un test optimal vous devez suivre les dernières étapes ci dessous, cela est très important pour que la DCE soit bien reconnu dans la private DNS Zone:

![image](https://github.com/user-attachments/assets/f70306a7-60be-4a6b-9c7a-5be6deefd72e)
![image](https://github.com/user-attachments/assets/da91d339-ec74-4067-b21a-4dbc14fd4aaf)
![image](https://github.com/user-attachments/assets/5ffc5cc1-d3f9-469c-b596-5b0fd5aeab23)

Une fois terminé, vous pouvez lancer la VM depuis le Bastion et laisser executer le script Powerhsell, après quelques minutes, la resource Azure Arc remonte correctement la policy applique l'extension AMA et vous pouvez consulter les logs de manière privé grâce au AMPLS

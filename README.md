# Terraform-Windows-VM-with-IIS-Server-and-Web-page
This Terraform project automates the deployment of a secure Windows Server environment in Microsoft Azure with integrated networking components and key management. As you will see the password is not hardcoded in Terraform, and instead it is saved in a Key vault and I'm injecting the contents of the key vault as my password. This prevents exposing your password in plain text and adds to the security. As an extra fan step I created an html website with fun messages displaying when hitting the button.

Note: In order to have this website appear when you browse for the IP of your VM you need to have the file named "index.html". Make sure you have an IIS web server installed in your vm from server manager
and make sure you add a certificate to your web server so it allows https connection. To generate a certificate open PowerShell as an admin in your vm and type "New-SelfSignedCertificate -DnsName "localhost", "$($env:COMPUTERNAME)" -CertStoreLocation "cert:\LocalMachine\My". Remember to save your file in "C:\inetpub\wwwroot" so it comes up when browsing the IP address.

Prerequisites:
- Terraform installed (v1.0+ recommended)
- Azure CLI installed and configured
- Active Azure subscription with sufficient permissions
- Azure service principal for authentication

Deployment Steps:
- Clone the repository

  git clone <repository-url>
  cd <repository-directory>

- Initialize Terraform
 
  terraform init

- Review the execution plan

  terraform plan

- Deploy the infrastructure

  terraform apply

- Import the resource group and key vault that is created in azure portal. The reason I imported those instead of ommiting this line is to avoid data loss. Type the below lines in terminal. Make sure you are logged in to your azure portal by entering "az login"

  Key vault import:
  terraform import azurerm_key_vault.trainingKeyVaultZotka /subscriptions/"Your subscription ID"/resourceGroups/trainingRG/providers/Microsoft.KeyVault/vaults/trainingKeyVaultZotka

  Resource group import:
  terraform import azurerm_resource_group.trainingRG /subscriptions/"Your subscription ID"/resourceGroups/trainingRG

- Destroy the infrastructure

    terraform destroy



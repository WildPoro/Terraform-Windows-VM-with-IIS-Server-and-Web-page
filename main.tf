# Configure the Azure provider
provider "azurerm" {
  features {} # Required for Azure provider
  subscription_id = var.ID # Use subscription ID from variables
}

# Define variables with default values
variable "location" {
  default = "West US 2" # Default Azure region for resources
}

variable "ID" {
  default = "Your subcription ID" # Azure subscription ID
}

# Create a resource group to contain all resources
resource "azurerm_resource_group" "trainingRG" {
  name     = "trainingRG" # Resource group name
  location = var.location # Region from variable
}

variable "tenantID" {
  default = "Your tenant ID" # Azure AD tenant ID
}

# Create virtual network with specified address space
resource "azurerm_virtual_network" "Vnet1" {
  name                = "Vnet1"
  address_space       = ["10.0.0.0/24"] # Network address range
  location            = var.location
  resource_group_name = azurerm_resource_group.trainingRG.name
}

# Create subnet within the virtual network
resource "azurerm_subnet" "Sub1" {
  name                 = "Sub1"
  resource_group_name  = azurerm_resource_group.trainingRG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = ["10.0.0.0/24"] # Subnet range (same as VNet in this case)
}

# Create network interface for the VM
resource "azurerm_network_interface" "NIC1" {
  name                = "Nic1"
  location            = var.location
  resource_group_name = azurerm_resource_group.trainingRG.name

  ip_configuration {
    name                          = "IP"
    subnet_id                     = azurerm_subnet.Sub1.id
    private_ip_address_allocation = "Dynamic" # Let Azure assign private IP
    public_ip_address_id          = azurerm_public_ip.PublicIP1.id # Attach public IP
  }
}

# Create public IP address for VM access
resource "azurerm_public_ip" "PublicIP1" {
  name                = "PublicIP1"
  location            = var.location
  resource_group_name = azurerm_resource_group.trainingRG.name
  allocation_method   = "Static" # Static IP won't change on restart
}

# Create network security group with inbound rules
resource "azurerm_network_security_group" "NSG1" {
  name                = "NSG1"
  location            = var.location
  resource_group_name = azurerm_resource_group.trainingRG.name

  security_rule {
    name                       = "AllowSSH-RDP-HTTPS"
    priority                   = 100 # Rule priority (lower numbers execute first)
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*" # Any source port
    destination_port_ranges    = ["22", "3389", "443"] # SSH, RDP, HTTPS
    source_address_prefix      = "*" # WARNING: In production, restrict this!
    destination_address_prefix = "*"
  }
}

# Associate NSG with network interface
resource "azurerm_network_interface_security_group_association" "nsgassoc" {
  network_interface_id      = azurerm_network_interface.NIC1.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}

# Create Key Vault for secure secret storage
resource "azurerm_key_vault" "trainingKeyVaultZotka" {
  name                = "trainingKeyVaultZotka"
  location            = var.location
  resource_group_name = azurerm_resource_group.trainingRG.name
  tenant_id           = var.tenantID # Azure AD tenant ID
  sku_name            = "standard" # Pricing tier
}

# Retrieve VM admin password from Key Vault
data "azurerm_key_vault_secret" "Passkey" {
  name         = "Passkey" # Secret name in Key Vault
  key_vault_id = azurerm_key_vault.trainingKeyVaultZotka.id
  depends_on   = [azurerm_key_vault_access_policy.policy] # Ensure policy exists first
}

# Set access policy for Key Vault
resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.trainingKeyVaultZotka.id
  tenant_id    = var.tenantID
  object_id    = data.azurerm_client_config.current.object_id # Current user/principal

  secret_permissions = ["Get", "List"] # Minimum permissions needed
}

# Get current Azure client config (used for Key Vault policy)
data "azurerm_client_config" "current" {}

# Create Windows virtual machine
resource "azurerm_windows_virtual_machine" "VM1" {
  name                = "VM1"
  resource_group_name = azurerm_resource_group.trainingRG.name
  location            = var.location
  size                = "Standard_DS1_v2" # VM size (1 vCPU, 3.5GB RAM)
  admin_username      = "kzotka" # Admin username
  admin_password      = data.azurerm_key_vault_secret.Passkey.value # Password from Key Vault
  network_interface_ids = [azurerm_network_interface.NIC1.id]

  os_disk {
    caching              = "ReadWrite" # Disk caching setting
    storage_account_type = "Standard_LRS" # Disk type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter" # Windows Server 2019
    version   = "latest"
  }
}

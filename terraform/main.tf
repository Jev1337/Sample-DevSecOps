terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create Resource Group
resource "azurerm_resource_group" "devsecops" {
  name     = "rg-devsecops-${random_string.suffix.result}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "DevSecOps"
    Owner       = var.owner
    CreatedBy   = "Terraform"
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "devsecops" {
  name                = "vnet-devsecops-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name

  tags = azurerm_resource_group.devsecops.tags
}

# Create Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.devsecops.name
  virtual_network_name = azurerm_virtual_network.devsecops.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "devsecops" {
  name                = "pip-devsecops-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.devsecops.name
  location            = azurerm_resource_group.devsecops.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.devsecops.tags
}

# Create Network Security Group for DevSecOps services
resource "azurerm_network_security_group" "devsecops" {
  name                = "nsg-devsecops-${random_string.suffix.result}"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip_cidr
    destination_address_prefix = "*"
  }

  # HTTP access
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS access
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Jenkins access
  security_rule {
    name                       = "Jenkins"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SonarQube access
  security_rule {
    name                       = "SonarQube"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Grafana access
  security_rule {
    name                       = "Grafana"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Flask App access
  security_rule {
    name                       = "FlaskApp"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.devsecops.tags
}

# Create Network Interface
resource "azurerm_network_interface" "devsecops" {
  name                = "nic-devsecops-${random_string.suffix.result}"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devsecops.id
  }

  tags = azurerm_resource_group.devsecops.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "devsecops" {
  network_interface_id      = azurerm_network_interface.devsecops.id
  network_security_group_id = azurerm_network_security_group.devsecops.id
}

# Generate SSH Key
resource "tls_private_key" "devsecops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save SSH private key locally
resource "local_file" "ssh_private_key" {
  content  = tls_private_key.devsecops.private_key_pem
  filename = "${path.module}/devsecops-key.pem"
  file_permission = "0600"
}

# Create Virtual Machine with Spot Instance
resource "azurerm_linux_virtual_machine" "devsecops" {
  name                = "vm-devsecops-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.devsecops.name
  location            = azurerm_resource_group.devsecops.location
  size                = var.vm_size
  admin_username      = var.admin_username
  priority            = "Spot"
  eviction_policy     = "Deallocate"
  max_bid_price       = var.max_bid_price

  # Disable password authentication
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.devsecops.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.devsecops.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Custom data script for initial setup
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username = var.admin_username
    setup_script   = base64encode(file("${path.module}/../setup.sh"))
  }))

  tags = merge(azurerm_resource_group.devsecops.tags, {
    Name = "DevSecOps-VM"
  })
}

# Create Storage Account for backups and logs
resource "azurerm_storage_account" "devsecops" {
  name                     = "stdevsecops${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.devsecops.name
  location                 = azurerm_resource_group.devsecops.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = azurerm_resource_group.devsecops.tags
}

# Create container for storing deployment artifacts
resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.devsecops.name
  container_access_type = "private"
}

# Create Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "devsecops" {
  name                = "law-devsecops-${random_string.suffix.result}"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = azurerm_resource_group.devsecops.tags
}

# Create Application Insights for application monitoring
resource "azurerm_application_insights" "devsecops" {
  name                = "ai-devsecops-${random_string.suffix.result}"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name
  workspace_id        = azurerm_log_analytics_workspace.devsecops.id
  application_type    = "web"

  tags = azurerm_resource_group.devsecops.tags
}

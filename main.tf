terraform {
  required_version = ">= 0.12.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
    google = ">=1.14.0"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name = "myTFResourceGroup"

  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name = "myTFVnet"
  address_space = ["10.0.0.0/16"]
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name = "myTFSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name = "myTFPublicIP"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  location = var.location
  name = "myTFNSG"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    access = "Allow"
    direction = "Inbound"
    name = "SSH"
    priority = 1001
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "nic" {
  location = var.location
  name = "myNIC"
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "myNICConfig"
    private_ip_address_allocation = "dynamic"
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  location = var.location
  name = "myTFVM"
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
    create_option = "FromImage"
    name = "myOsDisk"
    caching = "ReadWrite"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = lookup(var.sku, var.location)
    version = "latest"
  }

  os_profile {
    admin_username = var.admin_username
    computer_name = "myTFVM"
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "azurerm_public_ip" "ip" {
  name = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on = [azurerm_virtual_machine.vm]
}

data "google_dns_managed_zone" "container" {
  project = var.project_id != "" ? var.project_id : null
  name = var.managed_zone_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.ip.ip_address
}


#######################################################################
## Create Virtual Network - Spoke 1
#######################################################################

resource "azurerm_virtual_network" "spoke-1-vnet" {
  name                = "spoke-1-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  address_space       = ["172.16.1.0/24"]

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Subnets - Spoke 1
#######################################################################

resource "azurerm_subnet" "spoke-1-vm-subnet" {
  name                 = "vmSubnet"
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.spoke-1-vnet.name
  address_prefixes       = ["172.16.1.0/25"]

}

#######################################################################
## Create Virtual Network - Spoke 2
#######################################################################

resource "azurerm_virtual_network" "spoke-2-vnet" {
  name                = "spoke-2-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  address_space       = ["172.16.2.0/24"]

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}
#######################################################################
## Create Subnets - Spoke 2
#######################################################################
resource "azurerm_subnet" "spoke-2-vm-subnet" {
  name                 = "vmSubnet"
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.spoke-2-vnet.name
  address_prefixes       = ["172.16.2.0/25"]
}

#######################################################################
## Create NSG - Spoke 1
#######################################################################
resource "azurerm_network_security_group" "spoke-1-vnet-nsg"{
    name = "spoke-1-vnet-nsg"
    location            = var.location
    resource_group_name  = azurerm_resource_group.spoke-rg.name

    security_rule {
    name                       = "icmp"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "ICMP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}
#######################################################################
## Assign NSG - Spoke 1
#######################################################################
resource "azurerm_subnet_network_security_group_association" "spoke-1-vnet-nsg-ass" {
  subnet_id      = azurerm_subnet.spoke-1-vm-subnet.id
  network_security_group_id = azurerm_network_security_group.spoke-1-vnet-nsg.id
}

#######################################################################
## Create NSG - Spoke 2
#######################################################################
resource "azurerm_network_security_group" "spoke-2-vnet-nsg"{
    name = "spoke-2-vnet-nsg"
    location            = var.location
    resource_group_name  = azurerm_resource_group.spoke-rg.name

    security_rule {
    name                       = "icmp"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "ICMP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}
#######################################################################
## Assign NSG - Spoke 2
#######################################################################
resource "azurerm_subnet_network_security_group_association" "spoke-2-vnet-nsg-ass" {
  subnet_id      = azurerm_subnet.spoke-2-vm-subnet.id
  network_security_group_id = azurerm_network_security_group.spoke-2-vnet-nsg.id
}


#######################################################################
## Create Network Interface - Spoke 1
#######################################################################

resource "azurerm_network_interface" "spoke-1-nic" {
  name                 = "spoke-1-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "spoke-1-ipconfig"
    subnet_id                     = azurerm_subnet.spoke-1-vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}
#######################################################################
## Create Network Interface - Spoke 2
#######################################################################

resource "azurerm_network_interface" "spoke-2-nic" {
  name                 = "spoke-2-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "spoke-2-ipconfig"
    subnet_id                     = azurerm_subnet.spoke-2-vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Virtual Machine spoke-1
#######################################################################

resource "azurerm_windows_virtual_machine" "spoke-1-vm" {
  name                  = "spoke-1-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.spoke-rg.name
  network_interface_ids = [azurerm_network_interface.spoke-1-nic.id]
  size               = var.vmsize
  computer_name  = "spoke-1-vm"
  admin_username = var.username
  admin_password = var.password
  provision_vm_agent = true

    timezone = "W. Europe Standard Time"
  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name              = "spoke-1-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  
  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}
#######################################################################
## Create Virtual Machine spoke-2
#######################################################################
resource "azurerm_windows_virtual_machine" "spoke-2-vm" {
  name                  = "spoke-2-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.spoke-rg.name
  network_interface_ids = [azurerm_network_interface.spoke-2-nic.id]
  size               = var.vmsize
  computer_name  = "spoke-2-vm"
  admin_username = var.username
  admin_password = var.password
  provision_vm_agent = true

    timezone = "W. Europe Standard Time"
  identity {
    type = "SystemAssigned"
  }
  

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name              = "spoke-2-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Virtual Machine Auto Shutdown Schedule - spoke-1-vm
#######################################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "spoke-1-vm" {
  virtual_machine_id = azurerm_windows_virtual_machine.spoke-1-vm.id
  location              = var.location
  enabled            = true

  daily_recurrence_time = "2200"
  timezone              = "W. Europe Standard Time"

  notification_settings {
    enabled         = false
  }
}

#######################################################################
## Create Virtual Machine Auto Shutdown Schedule - spoke-2-vm
#######################################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "spoke-2-vm" {
  virtual_machine_id = azurerm_windows_virtual_machine.spoke-2-vm.id
  location              = var.location
  enabled            = true

  daily_recurrence_time = "2200"
  timezone              = "W. Europe Standard Time"

  notification_settings {
    enabled         = false
  }
}



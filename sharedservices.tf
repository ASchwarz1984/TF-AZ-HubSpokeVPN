#######################################################################
## Create Virtual Network - Services
#######################################################################
resource "azurerm_virtual_network" "services-vnet" {
  name                = "services-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.services-rg.name
  address_space       = ["172.16.10.0/24"]
  dns_servers         = ["192.168.1.201"]

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }

}
#######################################################################
## Create Subnets - Services
#######################################################################

resource "azurerm_subnet" "services-vm-1-subnet" {
  name                 = "servicesSubnet-1"
  resource_group_name = azurerm_resource_group.services-rg.name
  virtual_network_name = azurerm_virtual_network.services-vnet.name
  address_prefixes       = ["172.16.10.0/25"]
}

#######################################################################
## Create Subnets - NetApp Files
#######################################################################

resource "azurerm_subnet" "NetAppFiles-subnet" {
  name                 = "NetAppFiles"
  resource_group_name = azurerm_resource_group.services-rg.name
  virtual_network_name = azurerm_virtual_network.services-vnet.name
  address_prefixes       = ["172.16.10.128/25"]

  delegation {
  name = "netapp"

  service_delegation {
    name    = "Microsoft.Netapp/volumes"
    actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


#######################################################################
## Create NSG - services
#######################################################################
resource "azurerm_network_security_group" "services-vnet-nsg"{
    name = "services-vnet-nsg"
    location            = var.location
    resource_group_name = azurerm_resource_group.services-rg.name

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
## Assign NSG - hub
#######################################################################
resource "azurerm_subnet_network_security_group_association" "services-vnet-nsg-ass" {
  subnet_id      = azurerm_subnet.services-vm-1-subnet.id
  network_security_group_id = azurerm_network_security_group.services-vnet-nsg.id
}

#######################################################################
## Create Network Interface - ADDC
#######################################################################

resource "azurerm_network_interface" "services-dc-1-nic" {
  name                 = "services-dc-1-nic"
  location             = var.location
    resource_group_name = azurerm_resource_group.services-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "addc-1-ipconfig"
    subnet_id                     = azurerm_subnet.services-vm-1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Virtual Machine services-dc
#######################################################################
resource "azurerm_windows_virtual_machine" "services-dc-vm" {
  name                  = "services-dc-vm"
  location              = var.location
  resource_group_name = azurerm_resource_group.services-rg.name
  network_interface_ids = [azurerm_network_interface.services-dc-1-nic.id]
  size               = var.vmsize
  computer_name  = "services-dc-vm"
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
    name              = "services-dc-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Virtual Machine Auto Shutdown Schedule - services-dc-vm
#######################################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "services-dc-vm" {
  virtual_machine_id = azurerm_windows_virtual_machine.services-dc-vm.id
  location              = var.location
  enabled            = true

  daily_recurrence_time = "2210"
  timezone              = "W. Europe Standard Time"

  notification_settings {
    enabled         = false
  }
}

#######################################################################
## Create central Log analytics Workspace
#######################################################################
resource "azurerm_log_analytics_workspace" "centralLA" {
  name                = "LA-CentralHub-${var.location}"
  location              = var.location
  resource_group_name = azurerm_resource_group.services-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}


#######################################################################
## Create central Recovery Services Vault
#######################################################################
resource "azurerm_recovery_services_vault" "vault" {
  name                = "RSV-CentralHub-${var.location}"
  location              = var.location
  resource_group_name = azurerm_resource_group.services-rg.name
  sku                 = "Standard"
  soft_delete_enabled = true
  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}


#######################################################################
## Create Backup Policy
#######################################################################
resource "azurerm_backup_policy_vm" "rsv-vmpolicy" {
  name                = "rsv-vmpolicy"
  resource_group_name = azurerm_resource_group.services-rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  backup {
    frequency = "Daily"
    time      = "23:00"
    
  }
    retention_daily {
    count = 7
  }
}

#######################################################################
## Configure Backup for Service DC VM
#######################################################################
resource "azurerm_backup_protected_vm" "services-dc-vm" {
  resource_group_name = azurerm_resource_group.services-rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = azurerm_windows_virtual_machine.services-dc-vm.id
  backup_policy_id    = azurerm_backup_policy_vm.rsv-vmpolicy.id
}

#######################################################################
## Create Azure NetApp Files
#######################################################################
resource "azurerm_netapp_account" "anfacccount" {
  name                = "ANF-Account-1"
  location            = azurerm_resource_group.services-rg.location
  resource_group_name = azurerm_resource_group.services-rg.name
  
  active_directory {
    username            = var.domainadmin
    password            = var.domainpassword
    smb_server_name     = "ANFServer"
    dns_servers         = ["192.168.1.201"]
    domain              = "corp.theblacknet.de"
  }

}

resource "azurerm_netapp_pool" "anfpool" {
  name                = "ANF-Account-1-Pool-1"
  location            = azurerm_resource_group.services-rg.location
  resource_group_name = azurerm_resource_group.services-rg.name
  account_name        = azurerm_netapp_account.anfacccount.name
  service_level       = "Standard"
  size_in_tb          = 4
}

resource "azurerm_netapp_volume" "anfvol1" {
  lifecycle {
    prevent_destroy = true
  }

  name                = "ANF-Account-1-Pool-1-Vol-1"
  location            = azurerm_resource_group.services-rg.location
  resource_group_name = azurerm_resource_group.services-rg.name
  account_name        = azurerm_netapp_account.anfacccount.name
  pool_name           = azurerm_netapp_pool.anfpool.name
  volume_path         = "ANF-Account-1-Pool-1-Vol-1"
  service_level       = "Standard"
  subnet_id           = azurerm_subnet.NetAppFiles-subnet.id
  protocols           = ["CIFS"]
  security_style      = "Ntfs"
  storage_quota_in_gb = 100

}
#######################################################################
## Create Virtual Network - Hub
#######################################################################

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "hub-vnet"
  location            = var.location
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  address_space       = ["10.10.0.0/16"]
  dns_servers         = ["172.16.10.4"]

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Subnets - hub
#######################################################################
resource "azurerm_subnet" "hub-vm-subnet" {
  name                 = "vmSubnet"
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes       = ["10.10.3.0/24"]
}
resource "azurerm_subnet" "hub-bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes       = ["10.10.2.0/27"]
}
resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes       = ["10.10.1.0/27"]
}

#######################################################################
## Create NSG - hub
#######################################################################
resource "azurerm_network_security_group" "hub-vnet-nsg"{
    name = "hub-vnet-nsg"
    location            = var.location
    resource_group_name  = azurerm_resource_group.connectivityhub-rg.name

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
resource "azurerm_subnet_network_security_group_association" "hub-vnet-nsg-ass" {
  subnet_id      = azurerm_subnet.hub-vm-subnet.id
  network_security_group_id = azurerm_network_security_group.hub-vnet-nsg.id
}

#######################################################################
## Create Bastion Hub
#######################################################################
resource "azurerm_public_ip" "bastion-hub-pubip" {
  name                = "bastion-hub-pubip"
  location            = var.location
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-hub" {
  name                = "bastion-hub"
  location            = var.location
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name

  ip_configuration {
    name                 = "bastion-hub-configuration"
    subnet_id            = azurerm_subnet.hub-bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-hub-pubip.id
  }
}

#######################################################################
## Create Network Interface - HubVm
#######################################################################

resource "azurerm_network_interface" "hubvm-nic" {
  name                 = "hubvm-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "onprem-ipconfig"
    subnet_id                     = azurerm_subnet.hub-vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
      lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Virtual Machine hub
#######################################################################
resource "azurerm_windows_virtual_machine" "hub-vm" {
  name                  = "hub-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.connectivityhub-rg.name
  network_interface_ids = [azurerm_network_interface.hubvm-nic.id]
  size               = var.vmsize
  computer_name  = "hub-vm"
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
    name              = "hubvm-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
  lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

#######################################################################
## Create Virtual Machine Auto Shutdown Schedule - Hub-VM
#######################################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "hub-vm" {
  virtual_machine_id = azurerm_windows_virtual_machine.hub-vm.id
  location              = var.location
  enabled            = true

  daily_recurrence_time = "2200"
  timezone              = "W. Europe Standard Time"

  notification_settings {
    enabled         = false
  }
}



#######################################################################
## Create VNET Gateway - hub
#######################################################################
resource "azurerm_public_ip" "vnet-gw-pubip" {
    name                = "vnet-gw-pubip"
    location            = var.location
    resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
    allocation_method   = "Dynamic"
    sku                 = "Basic"
  }
  
  resource "azurerm_virtual_network_gateway" "vnet-gw" {
    name                = "vnet-gw"
    location            = var.location
    resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  
    type     = "Vpn"
    vpn_type = "RouteBased"
  
    active_active = false
    enable_bgp    = true
    sku           = "VpnGw1"

    /*  
    bgp_settings{
      asn = 64000
    }
    */

    ip_configuration {
      name                          = "vnet-gw-ip-config"
      public_ip_address_id          = azurerm_public_ip.vnet-gw-pubip.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.hub-gateway-subnet.id
    }
  }

#######################################################################
## Create Local Network Gateway
#######################################################################
  resource "azurerm_local_network_gateway" "LNG-USG" {
  name                = "LNG-USG"
  location            = var.location
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  gateway_fqdn = "RemoteGWPublic.Domain.com"
  address_space = [ "192.168.1.0/24" ]
  
  bgp_settings {
  asn = 65510
  bgp_peering_address = "192.168.1.1"  
  }
}

#######################################################################
## Create Gateway Connection
#######################################################################
resource "azurerm_virtual_network_gateway_connection" "CON-AZ-USG" {
  name                = "CON-AZ-USG"
  location            = var.location
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vnet-gw.id
  local_network_gateway_id   = azurerm_local_network_gateway.LNG-USG.id
  enable_bgp = true

  shared_key = "SharedSecretKey"
}
  

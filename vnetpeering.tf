##########################################################
## vNet Peering Spoke 1
##########################################################
resource "azurerm_virtual_network_peering" "HubtoSpoke1" {
  name                      = "HubtoSpoke1"
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-1-vnet.id
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  allow_gateway_transit = true
  depends_on = [azurerm_virtual_network_gateway.vnet-gw]  
}

resource "azurerm_virtual_network_peering" "Spoke1toHub" {
  name                      = "Spoke1toHub"
  resource_group_name = azurerm_resource_group.spoke-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-1-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  use_remote_gateways = true
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  depends_on = [azurerm_virtual_network_gateway.vnet-gw]
}

##########################################################
## vNet Peering Spoke 2
##########################################################
resource "azurerm_virtual_network_peering" "HubtoSpoke2" {
  name                      = "HubtoSpoke2"
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-2-vnet.id
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  allow_gateway_transit = true
  depends_on = [azurerm_virtual_network_gateway.vnet-gw]  
}

resource "azurerm_virtual_network_peering" "Spoke2toHub" {
  name                      = "Spoke2toHub"
  resource_group_name = azurerm_resource_group.spoke-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-2-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  use_remote_gateways = true
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  depends_on = [azurerm_virtual_network_gateway.vnet-gw]  
}

##########################################################
## vNet Peering Services Spoke
##########################################################
resource "azurerm_virtual_network_peering" "HubtoServices" {
  name                      = "HubtoServices"
  resource_group_name  = azurerm_resource_group.connectivityhub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.services-vnet.id
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  allow_gateway_transit = true
  depends_on = [azurerm_virtual_network_gateway.vnet-gw]  
  
}

resource "azurerm_virtual_network_peering" "ServicestoHub" {
  name                      = "ServicestoHub"
  resource_group_name = azurerm_resource_group.services-rg.name
  virtual_network_name      = azurerm_virtual_network.services-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  use_remote_gateways = true
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  depends_on = [azurerm_virtual_network_gateway.vnet-gw]
}
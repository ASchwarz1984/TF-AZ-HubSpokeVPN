provider "azurerm" {
  version = "2.43.0"
  features {}
}
#######################################################################
## Create Resource Group
#######################################################################

resource "azurerm_resource_group" "spoke-rg" {
  name     = "RG-spoke"
  location = var.location
  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
    lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

resource "azurerm_resource_group" "services-rg" {
  name     = "RG-services"
  location = var.location
  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
    lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}

resource "azurerm_resource_group" "connectivityhub-rg" {
  name     = "RG-connectivity-hub"
  location = var.location
  tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))
    lifecycle {
       ignore_changes = [tags.FirstApply]
  }
}


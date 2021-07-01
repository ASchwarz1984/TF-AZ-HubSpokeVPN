
##########################################################
## Install IIS role on spoke-1
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-spoke-1-vm" {
    
  name                 = "install-iis-spoke-1-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke-1-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
    depends_on = [azurerm_windows_virtual_machine.spoke-1-vm]

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}

##########################################################
## Install IIS role on spoke-2
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-spoke-2-vm" {
    
  name                 = "install-iis-spoke-2-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke-2-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  depends_on = [azurerm_windows_virtual_machine.spoke-2-vm]
  

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}

##########################################################
## Install IIS role on hub-vm
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-hub-vm" {
    
  name                 = "install-iis-hub-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.hub-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  depends_on = [azurerm_windows_virtual_machine.hub-vm]

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS

    tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))

    lifecycle {
        ignore_changes = [tags.FirstApply]
    }

}
##########################################################
## Install ADDC role on spoke-addc-vm
##########################################################
resource "azurerm_virtual_machine_extension" "install-spoke-addc-vm" {
    
    name                 = "install-spoke-addc-vm"
    virtual_machine_id   = azurerm_windows_virtual_machine.services-dc-vm.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"
    auto_upgrade_minor_version = true
    depends_on = [azurerm_windows_virtual_machine.services-dc-vm]

    settings = <<SETTINGS
        {            
            "fileUris":["https://gist.githubusercontent.com/ASchwarz1984/6220800d2a61122ab671e415536f160a/raw/0975e0f6ac53c4f8c1642c91f975836d97f6e0e9/addc.ps1"] 
        }
        SETTINGS
    
    protected_settings = <<PROTECTED_SETTINGS
        {
            "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File addc.ps1 ${var.domainadmin} ${var.domainpassword}"
        }
    PROTECTED_SETTINGS

    tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))

    lifecycle {
        ignore_changes = [tags.FirstApply]
    }
}


#######################################################################
## Domain Join - Hub-VM
#######################################################################
resource "azurerm_virtual_machine_extension" "domjoin" {
name = "domjoin"
virtual_machine_id = azurerm_windows_virtual_machine.hub-vm.id
publisher = "Microsoft.Compute"
type = "JsonADDomainExtension"
type_handler_version = "1.3"
auto_upgrade_minor_version = true
depends_on = [
    azurerm_windows_virtual_machine.hub-vm,
    azurerm_windows_virtual_machine.services-dc-vm,
    azurerm_virtual_machine_extension.install-spoke-addc-vm
]
# What the settings mean: https://docs.microsoft.com/en-us/windows/desktop/api/lmjoin/nf-lmjoin-netjoindomain
settings = <<SETTINGS
{
  "Name": "corp.theblacknet.de",
  "User": "${var.domainadmin}",
  "Restart": "true",
  "Options": "3"
}
SETTINGS
protected_settings = <<PROTECTED_SETTINGS
{
"Password": "${var.domainpassword}"
}
PROTECTED_SETTINGS

    tags = merge(local.tags, map("FirstApply", timestamp(), "LastApply", timestamp()))

    lifecycle {
        ignore_changes = [tags.FirstApply]
    }

}






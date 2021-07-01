variable "location" {
  description = "Location to deploy"
  type        = string
  default     = "WestEurope"
}

variable "username" {
  description = "Username for Virtual Machines"
  type        = string
  default     = "AzureAdmin"
}

variable "password" {
  description = "Virtual Machine password, must meet Azure complexity requirements"
   type        = string
   default     = "SecureP@ssword!"
}

variable "domainadmin" {
  description = "Username for Domain"
  type        = string
  default     = "UserName@Domain.com"
}

variable "domainpassword" {
  description = "Virtual Machine password, must meet Azure complexity requirements"
   type        = string
   default     = "SecureP@ssword!"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_B2s"
}

variable "tags" {
  type = map

  default = {
    Terraform = "true"
  }
}

locals {
  tags = "${merge(
    var.tags,
    map(
      
      "Location", "${var.location}"
    )
  )}"
}

variable "policy_definition_category" {
  type        = string
  description = "The category to use for all Policy Definitions"
  default     = "Custom"
}





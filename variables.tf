
# Azure Authentication

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Microsoft Entra Tenant ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Service Principal Client Secret"
  type        = string
  sensitive   = true
}

# Resource Group

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "rg-portfolio-vm-1"
}

# Virtual Network

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
  default     = "vnet-portfolio-1"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

# Subnet

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "subnet-portfolio"
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
  default     = ["10.40.1.0/24"]
}

# Public IP

variable "public_ip_name" {
  description = "Public IP name"
  type        = string
  default     = "pip-portfolio"
}

# Network Security Group

variable "nsg_name" {
  description = "NSG name"
  type        = string
  default     = "nsg-portfolio"
}

variable "ssh_allowed_ip" {
  description = "Your public IP in CIDR format"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_ip, 0))
    error_message = "Enter a valid IP CIDR, such as your-public-ip/32."
  }
}

# Network Interface

variable "nic_name" {
  description = "NIC name"
  type        = string
  default     = "nic-portfolio"
}

# Linux VM

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "vm-portfolio"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2als_v2"
}

variable "admin_username" {
  description = "Linux VM admin username"
  type        = string
  default     = "azadmin"
}

variable "admin_password" {
  description = "Linux VM administrator password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.admin_password) >= 12 &&
      length(var.admin_password) <= 123 &&
      can(regex("[A-Z]", var.admin_password)) &&
      can(regex("[a-z]", var.admin_password)) &&
      can(regex("[0-9]", var.admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.admin_password))
    )
    error_message = "Use 12-123 characters with uppercase, lowercase, number and special character."
  }
}

# Ubuntu Image

variable "os_publisher" {
  description = "Ubuntu publisher"
  type        = string
  default     = "Canonical"
}

variable "os_offer" {
  description = "Ubuntu offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "os_sku" {
  description = "Ubuntu image SKU"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "os_version" {
  description = "Ubuntu image version"
  type        = string
  default     = "latest"
}

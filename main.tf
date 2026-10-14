resource "azurerm_resource_group" "portfolio_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "portfolio_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.portfolio_rg.location
  resource_group_name = azurerm_resource_group.portfolio_rg.name
}

resource "azurerm_subnet" "portfolio_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.portfolio_rg.name
  virtual_network_name = azurerm_virtual_network.portfolio_vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_public_ip" "portfolio_ip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.portfolio_rg.location
  resource_group_name = azurerm_resource_group.portfolio_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "portfolio_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.portfolio_rg.location
  resource_group_name = azurerm_resource_group.portfolio_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-MyIP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "portfolio_nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.portfolio_rg.location
  resource_group_name = azurerm_resource_group.portfolio_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.portfolio_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.portfolio_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "portfolio_nic_nsg" {
  network_interface_id      = azurerm_network_interface.portfolio_nic.id
  network_security_group_id = azurerm_network_security_group.portfolio_nsg.id
}

resource "azurerm_linux_virtual_machine" "portfolio_vm" {
  name                = var.vm_name
  computer_name       = "portfoliovm"
  resource_group_name = azurerm_resource_group.portfolio_rg.name
  location            = azurerm_resource_group.portfolio_rg.location
  size                = var.vm_size

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.portfolio_nic.id
  ]

  os_disk {
    name                 = "osdisk-portfolio"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }

  depends_on = [
    azurerm_network_interface_security_group_association.portfolio_nic_nsg
  ]
}

resource "terraform_data" "deploy_portfolio" {
  triggers_replace = [
    filesha256("${path.module}/index.html"),
    filesha256("${path.module}/profile.jpg"),
    azurerm_public_ip.portfolio_ip.ip_address
  ]

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.portfolio_ip.ip_address
    user     = var.admin_username
    password = var.admin_password
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eux",
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo mkdir -p /var/www/html",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/index.html"
    destination = "/tmp/index.html"
  }

  provisioner "file" {
    source      = "${path.module}/profile.jpg"
    destination = "/tmp/profile.jpg"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/index.html /var/www/html/index.html",
      "sudo cp /tmp/profile.jpg /var/www/html/profile.jpg",
      "sudo chown -R www-data:www-data /var/www/html",
      "sudo chmod 755 /var/www/html",
      "sudo chmod 644 /var/www/html/index.html /var/www/html/profile.jpg",
      "sudo nginx -t",
      "sudo systemctl restart nginx"
    ]
  }

  depends_on = [
    azurerm_network_interface_security_group_association.portfolio_nic_nsg,
    azurerm_linux_virtual_machine.portfolio_vm
  ]
}

resource "azurerm_storage_account" "portfolio_storage" {
  name                = "kittuportfoliostg20262"
  resource_group_name = azurerm_resource_group.portfolio_rg.name
  location            = azurerm_resource_group.portfolio_rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = true
}

resource "azurerm_storage_account_static_website" "portfolio_website" {
  storage_account_id = azurerm_storage_account.portfolio_storage.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "azurerm_storage_blob" "portfolio_index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.portfolio_storage.name
  storage_container_name = "$web"

  type         = "Block"
  source       = "${path.module}/index.html"
  content_type = "text/html; charset=utf-8"

  depends_on = [
    azurerm_storage_account_static_website.portfolio_website
  ]
}

resource "azurerm_storage_blob" "portfolio_image" {
  name                   = "profile.jpg"
  storage_account_name   = azurerm_storage_account.portfolio_storage.name
  storage_container_name = "$web"

  type         = "Block"
  source       = "${path.module}/profile.jpg"
  content_type = "image/jpeg"

  depends_on = [
    azurerm_storage_account_static_website.portfolio_website
  ]
}

output "storage_website_url" {
  description = "Azure Storage static website URL"
  value       = azurerm_storage_account.portfolio_storage.primary_web_endpoint
}

output "vm_public_ip" {
  description = "Azure VM public IP"
  value       = azurerm_public_ip.portfolio_ip.ip_address
}

output "portfolio_url" {
  description = "Portfolio website URL"
  value       = "http://${azurerm_public_ip.portfolio_ip.ip_address}"
}

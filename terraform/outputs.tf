output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.devsecops.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.devsecops.name
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.devsecops.ip_address
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.devsecops.private_ip_address
}

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i devsecops-key.pem ${var.admin_username}@${azurerm_public_ip.devsecops.ip_address}"
}

output "service_urls" {
  description = "URLs for accessing DevSecOps services"
  value = {
    jenkins   = "http://${azurerm_public_ip.devsecops.ip_address}:8080"
    sonarqube = "http://${azurerm_public_ip.devsecops.ip_address}:9000"
    grafana   = "http://${azurerm_public_ip.devsecops.ip_address}:3000"
    flask_app = "http://${azurerm_public_ip.devsecops.ip_address}:5000"
  }
}

output "nip_io_urls" {
  description = "nip.io URLs for accessing DevSecOps services"
  value = {
    jenkins   = "http://jenkins.${azurerm_public_ip.devsecops.ip_address}.nip.io"
    sonarqube = "http://sonarqube.${azurerm_public_ip.devsecops.ip_address}.nip.io"
    grafana   = "http://grafana.${azurerm_public_ip.devsecops.ip_address}.nip.io"
    flask_app = "http://app.${azurerm_public_ip.devsecops.ip_address}.nip.io"
  }
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.devsecops.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.devsecops.workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.devsecops.instrumentation_key
  sensitive   = true
}

output "spot_instance_info" {
  description = "Spot instance configuration"
  value = {
    vm_size       = azurerm_linux_virtual_machine.devsecops.size
    priority      = azurerm_linux_virtual_machine.devsecops.priority
    max_bid_price = azurerm_linux_virtual_machine.devsecops.max_bid_price
  }
}

output "setup_commands" {
  description = "Commands to run after VM is provisioned"
  value = [
    "# Connect to the VM:",
    "ssh -i devsecops-key.pem ${var.admin_username}@${azurerm_public_ip.devsecops.ip_address}",
    "",
    "# Check cloud-init status:",
    "sudo cloud-init status",
    "",
    "# View setup logs:",
    "sudo journalctl -u cloud-final",
    "",
    "# Run the DevSecOps setup (if not auto-started):",
    "cd /home/${var.admin_username}/Sample-DevSecOps && sudo ./setup.sh",
    "",
    "# Or run in development mode:",
    "cd /home/${var.admin_username}/Sample-DevSecOps && docker-compose up -d"
  ]
}

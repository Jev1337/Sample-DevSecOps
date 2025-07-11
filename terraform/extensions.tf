# Add auto-shutdown schedule for cost optimization
resource "azurerm_dev_test_global_vm_shutdown_schedule" "devsecops" {
  count              = var.auto_shutdown_enabled ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.devsecops.id
  location           = azurerm_resource_group.devsecops.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled = false
  }

  tags = azurerm_resource_group.devsecops.tags
}

# Create managed disk for persistent storage
resource "azurerm_managed_disk" "devsecops_data" {
  name                 = "disk-devsecops-data-${random_string.suffix.result}"
  location             = azurerm_resource_group.devsecops.location
  resource_group_name  = azurerm_resource_group.devsecops.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = azurerm_resource_group.devsecops.tags
}

# Attach data disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "devsecops_data" {
  managed_disk_id    = azurerm_managed_disk.devsecops_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.devsecops.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Create backup vault for VM backups
resource "azurerm_recovery_services_vault" "devsecops" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "rsv-devsecops-${random_string.suffix.result}"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name
  sku                 = "Standard"
  soft_delete_enabled = false

  tags = azurerm_resource_group.devsecops.tags
}

# VM Extensions for monitoring
resource "azurerm_virtual_machine_extension" "azure_monitor" {
  count                = var.enable_monitoring ? 1 : 0
  name                 = "AzureMonitorLinuxAgent"
  virtual_machine_id   = azurerm_linux_virtual_machine.devsecops.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"

  tags = azurerm_resource_group.devsecops.tags
}

# Data Collection Rule for monitoring
resource "azurerm_monitor_data_collection_rule" "devsecops" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "dcr-devsecops-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.devsecops.name
  location            = azurerm_resource_group.devsecops.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.devsecops.id
      name                  = "log-analytics-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["log-analytics-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      name           = "syslog-data-source"
    }

    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\Disk Writes/sec",
        "\\LogicalDisk(_Total)\\Disk Reads/sec",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
      name = "performance-counters"
    }
  }

  tags = azurerm_resource_group.devsecops.tags
}

# Associate DCR with VM
resource "azurerm_monitor_data_collection_rule_association" "devsecops" {
  count                   = var.enable_monitoring ? 1 : 0
  name                    = "dcra-devsecops-${random_string.suffix.result}"
  target_resource_id      = azurerm_linux_virtual_machine.devsecops.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.devsecops[0].id
}

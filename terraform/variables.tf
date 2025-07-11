variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevSecOps-Team"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_ip_cidr" {
  description = "IP CIDR block for admin access (your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "max_bid_price" {
  description = "Maximum bid price for spot instance (in USD). Set to -1 for pay-as-you-go pricing."
  type        = number
  default     = 0.10
}

variable "disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 64
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for cost optimization"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time for auto-shutdown (24-hour format)"
  type        = string
  default     = "2300"
}

variable "auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown"
  type        = string
  default     = "UTC"
}

variable "enable_monitoring" {
  description = "Enable Azure monitoring and logging"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

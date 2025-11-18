variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
  type        = number
}

variable "target_node" {
  description = "Proxmox node to deploy VM on"
  type        = string
}

variable "clone_template" {
  description = "Template to clone from"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "20G"
}

variable "storage" {
  description = "Storage location"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "IP address (CIDR notation)"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = ""
}

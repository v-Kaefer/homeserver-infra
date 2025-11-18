resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  clone       = var.clone_template
  
  # VM specs
  cores   = var.cores
  memory  = var.memory
  
  # Disk configuration
  disk {
    size    = var.disk_size
    storage = var.storage
    type    = "scsi"
  }
  
  # Network configuration
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  # Cloud-init configuration (if applicable)
  ipconfig0 = var.ip_address != "dhcp" ? "ip=${var.ip_address},gw=${var.gateway}" : "ip=dhcp"
  
  # General settings
  agent      = 1
  onboot     = true
  os_type    = "cloud-init"
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

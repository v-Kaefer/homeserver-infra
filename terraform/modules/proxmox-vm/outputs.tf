output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_ip" {
  description = "The IP address of the VM"
  value       = proxmox_vm_qemu.vm.default_ipv4_address
}

#! /bin/sh

set -euo pipefail

# Ensure the install directory variables are loaded
. ./build-vars

echo "[INFO] Checking for ID conflicts..."
# Check if a config file for this VM ID already exists in Proxmox
if [ -f "/etc/pve/qemu-server/${build_vm_id}.conf" ]; then
  echo "[ERROR] VM ID ${build_vm_id} already exists! Aborting to prevent data loss."
  exit 1
fi

echo "[INFO] Cleaning up old staging files."
rm -f "${install_dir}/${image_name}"

echo "[INFO] Downloading NixOS 26.05 VMA image from Hydra..."
if ! wget --content-disposition -q "${vma_url}" -O "${install_dir}/${image_name}"; then
  echo "[ERROR] Unable to download the image. Script terminated."
  exit 1
fi

echo "[INFO] Restoring VM from VMA backup archive."
# The --unique 1 flag ensures Proxmox generates new MAC addresses for the restored VM interfaces
sudo qmrestore "${install_dir}/${image_name}" "${build_vm_id}" --storage "${storage_location}" --unique 1

echo "[INFO] Setting up Cloud-Init User Data Snippet..."
sudo mkdir -p /var/lib/vz/snippets
sudo cp "${install_dir}/nixos-user-data.yaml" "/var/lib/vz/snippets/nixos-${build_vm_id}-userdata.yaml"

echo "[INFO] Configuring VM Hardware and Cloud-Init Overrides..."
sudo qm set "${build_vm_id}" \
  --name "${template_name}" \
  --memory "${vm_mem}" \
  --cores "${vm_cores}" \
  --net0 "virtio,bridge=vmbr0,firewall=1" \
  --scsihw "${scsihw}" \
  --ide0 "${storage_location}:cloudinit" \
  --nameserver "${nameserver}" \
  --ostype l26 \
  --searchdomain "${searchdomain}" \
  --sshkeys "${keyfile}" \
  --ciuser "${cloud_init_user}" \
  --ipconfig0 ip=dhcp \
  --boot c \
  --bootdisk scsi0 \
  --machine q35 \
  --bios ovmf \
  --efidisk0 "${storage_location}:0,efitype=4m,pre-enrolled-keys=1" \
  --agent enabled=1 \
  --cicustom "vendor=local:snippets/nixos-${build_vm_id}-userdata.yaml"

echo "[INFO] Conversion to template."
sudo qm template "${build_vm_id}"

echo "[SUCCESS] NixOS 26.05 Template successfully created."
#! /bin/sh

set -eu

# --- SMART SUDO CHECK ---
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo "
else
  echo "[ERROR] This script requires root privileges. Please run as root"
  exit 1
fi
# ------------------------

# Ensure the install directory variables are loaded
. ./build-vars

echo "[INFO] Checking for ID conflicts..."
if [ -f "/etc/pve/qemu-server/${build_vm_id}.conf" ]; then
  echo "[ERROR] VM ID ${build_vm_id} already exists! Aborting to prevent data loss."
  exit 1
fi

echo "[INFO] Cleaning up old staging files."
rm -f "${install_dir}/${image_name}"

echo "[INFO] Downloading NixOS 26.05 VMA image from Hydra..."
if ! curl -f -L -s "${vma_url}" -o "${install_dir}/${image_name}"; then
  echo "[ERROR] Download failed! The Hydra URL returned a 404."
  exit 1
fi

echo "[INFO] Restoring VM from VMA backup archive."
${SUDO}qmrestore "${install_dir}/${image_name}" "${build_vm_id}" --storage "${storage_location}" --unique 1

echo "[INFO] Setting up Cloud-Init User Data Snippet..."
${SUDO}mkdir -p /var/lib/vz/snippets
${SUDO}cp "${install_dir}/nixos-user-data.yaml" "/var/lib/vz/snippets/nixos-${build_vm_id}-userdata.yaml"

echo "[INFO] Configuring VM Hardware and Cloud-Init Overrides..."
${SUDO}qm set "${build_vm_id}" \
  --name "${template_name}" \
  --memory "${vm_mem}" \
  --cores "${vm_cores}" \
  --net0 "virtio,bridge=vmbr0,firewall=1" \
  --nameserver "${nameserver}" \
  --ostype l26 \
  --searchdomain "${searchdomain}" \
  --sshkeys "${keyfile}" \
  --ciuser "${cloud_init_user}" \
  --ipconfig0 ip=dhcp \
  --boot order=virtio0 \
  --machine q35 \
  --bios seabios \
  --agent enabled=1 \
  --cicustom "vendor=local:snippets/nixos-${build_vm_id}-userdata.yaml"

echo "[INFO] Conversion to template."
${SUDO}qm template "${build_vm_id}"

echo "[SUCCESS] NixOS 26.05 Template successfully created."
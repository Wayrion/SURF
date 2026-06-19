#! /bin/sh

# This script will download and modify the desired image to prep for template build.
# I cloned this script from Geektx: https://github.com/geektx/Proxmox-VM-Template/ and modified it.

# Geektx was inspired by 2 separate authors work:
# Austins Nerdy Things: https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image/
# What the Server: https://whattheserver.com/proxmox-cloud-init-os-template-creation/
# requires libguestfs-tools to be installed.
# This script is designed to be run inside the ProxMox VE host environment.
# Modify the install_dir variable to reflect where you have placed the script and associated files.

set -euo pipefail

. ./build-vars

# Check for pre-existing VMs with the same ID and stop if there's a conflict

echo "[INFO] Checking for ID conflicts..."
if [ -f "/etc/pve/qemu-server/${build_vm_id}.conf" ]; then
  echo "[ERROR] VM ID ${build_vm_id} already exists! Aborting to prevent data loss."
  exit 1
fi

# Grab latest cloud-init image for your selected image

echo "[INFO] Download image from ${cloud_img_url}..."
if ! wget -q "${cloud_img_url}"; then
  echo "[ERROR] Unable to download the image. Script terminated."
  exit 1
fi

# insert commands to populate the currently empty build-info file
cat > "${install_dir}build-info" <<EOF
Base Image: ${image_name}
Packages added at build time: ${package_list}
Build date: $(date)
Build creator: ${creator}
EOF

echo "[INFO] Image customisation."
virt-customize \
  --update \
  --install "${package_list}" \
  --mkdir "${build_info_file_location}" \
  --copy-in "${install_dir}build-info:${build_info_file_location}" \
  -a "${image_name}"

# VM management
echo "[INFO] Deletion of the old VM (if it exists)."
sudo qm destroy "${build_vm_id}" --purge || true

#create with default BIOS (SeaBIOS)
#sudo qm create ${build_vm_id} --memory ${vm_mem} --cores ${vm_cores} --net0 virtio,bridge=vmbr0,firewall=1 --name ${template_name} --machine q35 --cpu x86-64-v4
#create with OVMF (UEFI) bios -essentially only needed for windows but has larger console screen

echo "[INFO] Creating the VM."
sudo qm create "${build_vm_id}" \
  --memory "${vm_mem}" \
  --cores "${vm_cores}" \
  --net0 "virtio,bridge=vmbr0,firewall=1" \
  --name "${template_name}" \
  --machine q35 \
  --bios ovmf \
  --cpu x86-64-v4

#resize disk to 32G

echo "[INFO] Resizing the disk."
qemu-img resize "${image_name}" 32G

echo "[INFO] Cleaning machine-id and DHCP."
virt-sysprep -a "${image_name}" --operations machine-id,dhcp-client-state

echo "[INFO] Importing and configuring the disc."
sudo qm importdisk "${build_vm_id}" "${image_name}" "${storage_location}"

sudo qm set "${build_vm_id}" \
  --scsihw "${scsihw}" \
  --scsi0 "${storage_location}:vm-${build_vm_id}-disk-0" \
  --ide0 "${storage_location}:cloudinit" \
  --nameserver "${nameserver}" \
  --ostype l26 \
  --searchdomain "${searchdomain}" \
  --sshkeys "${keyfile}" \
  --ciuser "${cloud_init_user}" \
  --ipconfig0 ip=dhcp \
  --boot c \
  --bootdisk scsi0 \
  --efidisk0 "${storage_location}:0,efitype=4m,pre-enrolled-keys=1" \
  --agent enabled=1

#in order to copy the right UEFI keys, we need to use :0 and the efidisk will be correctly filled
#qm set ${build_vm_id} --serial0 socket --vga serial0

echo "[INFO] Conversion to template."
sudo qm template "${build_vm_id}"

echo "[SUCCESS] Template successfully created."

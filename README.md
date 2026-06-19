# SURF
Open-source repository for my work at SURF. the copyright license applies to the whole project unless otherwise specified in the folder specific READMEs.

# Proxmox-Nix-Template:
A sciprt to automatically create a Proxmox Template for NixOS

# GenAI Disclosure:
As per the NLNet guidelines on GenAI disclosure (https://nlnet.nl/foundation/policies/generativeAI/)
All commit messages marked with [GenAI], are the commits were GenAI was used to modify or create, in part or the whole change.

## Proxmox Nix Template:
GenAI was mainly used to to quickly create an idomatic port of [Proxmox-Debian-Template](https://codeberg.org/efef/Proxmox-VM-Template). Upon review of the created port, it was determined that the AI generated potentially destructive commands in the script, which was then caught and changed before committing. Furthermore, issues were encountered with NixOS not booting with the UEFI firmware type, so that was also changed to the Legacy Seabios. AI was used here to change the keyword in the build var. Also under manual testing it was realized that the script was problematic if ran as root user, as it would just return sudo not found, as the user is already sudo. The AI was then prompted again to create a check, to see if the user is already sudo, to decide wether to use the sudo prefix in the commands or not.

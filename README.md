# SURF
Open-source repository for my work at SURF. the copyright license applies to the whole project unless otherwise specified in the folder specific READMEs.

# Proxmox-Nix-Template:
A sciprt to automatically create a Proxmox Template for NixOS

# GenAI Disclosure:
As per the NLNet guidelines on GenAI disclosure (https://nlnet.nl/foundation/policies/generativeAI/)
All commit messages marked with [GenAI], are the commits were GenAI was used to modify or create, in part or the whole change. Unless otherwise mentioned, Google Gemini v3.1 Preview (June/July Edition) were used through [gemini.google.com](https://gemini.google.com/), with a Paid License. Under [Google's Terms of Service](https://policies.google.com/terms#toc-content) under the section of „Content in Google services“ for paid users „Your content. Some of our services allow you to generate original content. Google won’t claim ownership over that content.“

## Proxmox Nix Template:
GenAI was mainly used to to quickly create an line-by-line port of [Proxmox-Debian-Template](https://codeberg.org/efef/Proxmox-VM-Template). Upon review of the created port, it was determined that the AI generated potentially destructive commands in the script, which was then caught and changed before committing. Furthermore, issues were encountered with NixOS not booting with the UEFI firmware type, so that was also changed to the Legacy Seabios. AI was used here to change the keyword in the build var. Also under manual testing it was realized that the script was problematic if ran as root user, as it would just return sudo not found, as the user is already sudo. The AI was then prompted again to create a check, to see if the user is already sudo, to decide wether to use the sudo prefix in the commands or not. After the AI generated the output, the code was then tested both on personal and on SURF infrastructure with further patches being manually done. AI was mainly used to do the busy work.

Furthermore, after the port was created, some methodology changes were manually made like opting to use VMA images from [Hydra](https://hydra.nixos.org/) as opposed to qcow2 images. This is because of the builds available from Hydra and due to the convenience of using VMA images with Proxmox. 

# Acknowledgements
Some of the development in this repository is funded by the [Next Generation Internet (NGI)](https://www.ngi.eu/) initiative through the [NLNet Foundation](https://nlnet.nl/).

[<img src="https://nlnet.nl/image/logos/NGI_tag.svg" alt="NGI Fund logo" style="width:10rem;" />](https://nlnet.nl/NGI0/)
&nbsp;&nbsp;
[<img src="https://nlnet.nl/image/logos/EC.svg" alt="European Commission logo" style="width:10rem;" />](https://ngi.eu/about/)
&nbsp;&nbsp;
[<img src="https://nlnet.nl/logo/banner.svg" alt="NLnet foundation logo" style="width:10rem;" />](https://nlnet.nl/foundation/)
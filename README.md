# Clone Ubuntu OS

Safe utility to clone an existing Ubuntu installation to another drive with GPT, EFI, and a storage partition.

WARNING: The destination drive will be erased. Double-check devices before proceeding.

Requirements (on Ubuntu live/system):
- sudo, parted, rsync, exfatprogs, efibootmgr, pv, curl

Usage:
1) Run: bash ./clone_ubuntu_os_pv.sh
2) Select source disk (clone FROM) and destination disk (clone TO)
3) Enter Ubuntu partition size (default 128GB)
4) Wait for cloning; GRUB will be installed on the destination

Update script:
- From menu option 3, self-update checks the VERSION file from this GitHub repo (auto-detected from git remote).

Icons tooling:
- scripts/convert-icons.sh or scripts/convert-icons.ps1 convert build/icon.svg into PNGs, .ico, and .icns for app packaging.

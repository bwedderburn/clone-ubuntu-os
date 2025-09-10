#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
LOGFILE="/var/log/clone_to_movespeed.log"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

START_TIME=$(date +%s)

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo -ne "    \b\b\b\b"
}

cleanup() {
    echo -e "${YELLOW}[!] Cleaning up mounts...${NC}"
    for dir in /dev/pts /dev /proc /sys /run; do
        umount /mnt/dst$dir 2>/dev/null || true
    done
    umount /mnt/dst/boot/efi 2>/dev/null || true
    umount -R /mnt/src 2>/dev/null || true
    umount -R /mnt/dst 2>/dev/null || true
    umount -R /mnt/efi-old 2>/dev/null || true
    umount -R /mnt/efi-new 2>/dev/null || true
}
trap cleanup EXIT

detect_drives() {
    echo -e "${BLUE}[*] Listing available drives...${NC}"
    lsblk -o NAME,SIZE,MODEL

    echo -e "${YELLOW}Choose SOURCE drive (the one to clone FROM):${NC}"
    read -rp "Source drive (e.g., sdb): " SRC
    SRC_DRIVE="/dev/$SRC"

    echo -e "${YELLOW}Choose DESTINATION drive (the one to clone TO - will be ERASED):${NC}"
    read -rp "Destination drive (e.g., sda): " DST
    DST_DRIVE="/dev/$DST"

    if [[ "$SRC_DRIVE" == "$DST_DRIVE" ]]; then
        echo -e "${RED}[!] Source and destination cannot be the same!${NC}"
        exit 1
    fi

    if mount | grep -q "$DST"; then
        echo -e "${RED}[!] Destination drive $DST_DRIVE is mounted! Please unmount before proceeding.${NC}"
        exit 1
    fi

    echo -e "${BLUE}Source:${NC}"
    lsblk -o NAME,SIZE,MODEL | grep -E "^$SRC|─$SRC"
    echo -e "${BLUE}Destination:${NC}"
    lsblk -o NAME,SIZE,MODEL | grep -E "^$DST|─$DST"

    echo -e "${RED}WARNING: This will ERASE ALL DATA on $DST_DRIVE!${NC}"
    read -rp "Type 'YES' to confirm: " FINAL_CONFIRM
    if [[ "$FINAL_CONFIRM" != "YES" ]]; then
        echo -e "${RED}Aborting.${NC}"
        exit 1
    fi

    SRC_ROOT=$(findmnt -no SOURCE /)
    SRC_EFI=$(findmnt -no SOURCE /boot/efi || true)
    DST_ROOT="${DST_DRIVE}2"
    DST_EFI="${DST_DRIVE}1"
    DST_EXFAT="${DST_DRIVE}3"
}

update_script() {
    echo -e "${BLUE}=== SELF-UPDATE ===${NC}"
    REPO_BASE="https://raw.githubusercontent.com/yourusername/clone-to-movespeed/main"
    VERSION_URL="$REPO_BASE/VERSION"
    SCRIPT_URL="$REPO_BASE/clone_to_movespeed_pv.sh"
    CHANGELOG_URL="$REPO_BASE/CHANGELOG.md"
    TMP_FILE="/tmp/clone_to_movespeed_pv.sh"

    echo -e "${BLUE}[*] Checking latest version...${NC}"
    REMOTE_VERSION=$(curl -fsSL "$VERSION_URL" || echo "")
    if [[ -z "$REMOTE_VERSION" ]]; then
        echo -e "${RED}[!] Could not fetch remote version.${NC}"
        return 1
    fi

    echo -e "${BLUE}Local version:${NC} $VERSION"
    echo -e "${BLUE}Remote version:${NC} $REMOTE_VERSION"

    if [[ "$REMOTE_VERSION" == "$VERSION" ]]; then
        echo -e "${GREEN}Already up to date.${NC}"
        return 0
    fi

    echo -e "${BLUE}[*] Downloading latest script...${NC}"
    curl -fsSL "$SCRIPT_URL" -o "$TMP_FILE" &
    spinner $!

    if [[ -f "$TMP_FILE" ]]; then
        echo -e "${GREEN}Updating script...${NC}"
        sudo mv "$TMP_FILE" "$0"
        sudo chmod +x "$0"
        echo -e "${GREEN}Script updated to version $REMOTE_VERSION! Restarting...${NC}"

        echo -e "${BLUE}[*] Fetching CHANGELOG...${NC}"
        curl -fsSL "$CHANGELOG_URL" -o /tmp/CHANGELOG.md &
        spinner $!
        if [[ -f /tmp/CHANGELOG.md ]]; then
            echo -e "${BLUE}=== LATEST CHANGELOG ===${NC}"
            awk '/^## / && ++count>1 {exit} {print}' /tmp/CHANGELOG.md
            echo -e "${BLUE}========================${NC}"
        else
            echo -e "${YELLOW}[!] No CHANGELOG found.${NC}"
        fi

        exec "$0"
    else
        echo -e "${RED}[!] Failed to download the latest script.${NC}"
    fi
}

run_clone() {
    exec > >(tee -a $LOGFILE) 2>&1
    detect_drives

    read -rp "Enter Ubuntu partition size in GB (default 128): " UBUNTU_SIZE
    UBUNTU_SIZE=${UBUNTU_SIZE:-128}

    echo -e "${BLUE}[*] Installing required packages...${NC}"
    (sudo apt update && sudo apt install -y gparted rsync exfatprogs efibootmgr pv curl) &
    spinner $!

    echo -e "${BLUE}[*] Wiping partition table...${NC}"
    sudo wipefs -a $DST_DRIVE &
    spinner $!

    echo -e "${BLUE}[*] Creating partitions...${NC}"
    (sudo parted -s $DST_DRIVE mklabel gpt &&     sudo parted -s $DST_DRIVE mkpart EFI fat32 1MiB 513MiB &&     sudo parted -s $DST_DRIVE set 1 esp on &&     sudo parted -s $DST_DRIVE mkpart UBUNTU ext4 513MiB ${UBUNTU_SIZE}GiB &&     sudo parted -s $DST_DRIVE mkpart STORAGE ${UBUNTU_SIZE}GiB 100%) &
    spinner $!

    echo -e "${BLUE}[*] Formatting partitions...${NC}"
    (sudo mkfs.vfat -F32 $DST_EFI && sudo mkfs.ext4 -F $DST_ROOT && sudo mkfs.exfat $DST_EXFAT) &
    spinner $!

    echo -e "${BLUE}[*] Cloning root filesystem...${NC}"
    (sudo mkdir -p /mnt/src /mnt/dst &&     sudo mount $SRC_ROOT /mnt/src &&     sudo mount $DST_ROOT /mnt/dst &&     sudo rsync -aAXH --info=progress2 /mnt/src/ /mnt/dst/) &
    spinner $!

    echo -e "${BLUE}[*] Cloning EFI partition...${NC}"
    (sudo mkdir -p /mnt/efi-old /mnt/efi-new &&     sudo mount $SRC_EFI /mnt/efi-old &&     sudo mount $DST_EFI /mnt/efi-new &&     sudo rsync -aAXH --info=progress2 /mnt/efi-old/ /mnt/efi-new/) &
    spinner $!

    echo -e "${BLUE}[*] Installing GRUB bootloader...${NC}"
    (sudo mkdir -p /mnt/dst/boot/efi && sudo mount $DST_EFI /mnt/dst/boot/efi &&     for dir in /dev /dev/pts /proc /sys /run; do sudo mount --bind $dir /mnt/dst$dir; done &&     sudo chroot /mnt/dst grub-install $DST_DRIVE && sudo chroot /mnt/dst update-grub) &
    spinner $!

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    echo -e "${GREEN}=== Clone Complete! ===${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${GREEN}Clone Summary:${NC}"
    echo -e "${BLUE}=============================================${NC}"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL | grep -E "$(basename $DST_DRIVE|sed 's/[0-9]*$//')"
    echo -e "${YELLOW}Elapsed Time:${NC} ${ELAPSED}s"
    df -h | grep "$(basename $DST_DRIVE)"
    echo -e "${BLUE}=============================================${NC}"
}

menu() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE} Ubuntu Clone Utility (Safe Multi-Drive)${NC}"
    echo -e "${BLUE} Version: $VERSION${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${YELLOW}1) Run Full Clone${NC}"
    echo -e "${YELLOW}2) Dry Run (simulate only)${NC}"
    echo -e "${YELLOW}3) Show Status (drives, partitions, mounts)${NC}"
    echo -e "${YELLOW}4) Exit${NC}"
    echo -e "${YELLOW}5) Safe Mode (read-only verification)${NC}"
    echo -e "${YELLOW}6) Backup Only (make compressed image, no writing)${NC}"
    echo -e "${YELLOW}7) Restore Mode (write backup image to target drive)${NC}"
    echo -e "${YELLOW}8) Update Script (fetch latest version)${NC}"
    echo -e "${BLUE}=============================================${NC}"
    read -rp "Choose an option [1-8]: " choice
}

while true; do
    menu
    case $choice in
        1) run_clone; break;;
        2) dry_run; break;;
        3) show_status;;
        4) echo -e "${GREEN}Exiting.${NC}"; exit 0;;
        5) safe_mode;;
        6) backup_only;;
        7) restore_mode;;
        8) update_script;;
        *) echo -e "${RED}Invalid choice, please select 1-8.${NC}";;
    esac
done

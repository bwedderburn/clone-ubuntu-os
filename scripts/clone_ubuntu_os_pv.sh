#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.2"
LOGFILE="/tmp/clone-ubuntu-os.log"

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
        spinstr=$temp${spinstr%$temp}
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

    # Validate that devices exist and are whole disks (not partitions)
    for d in "$SRC_DRIVE" "$DST_DRIVE"; do
        if [[ ! -b "$d" ]]; then
            echo -e "${RED}[!] Device $d does not exist.${NC}"
            exit 1
        fi
        if ! lsblk -dn -o TYPE "$d" | grep -qx disk; then
            echo -e "${RED}[!] $d is not a disk device (do not use a partition like sda1).${NC}"
            exit 1
        fi
    done

    if [[ "$SRC_DRIVE" == "$DST_DRIVE" ]]; then
        echo -e "${RED}[!] Source and destination cannot be the same!${NC}"
        exit 1
    fi

    if mount | grep -qE "/dev/$(basename "$DST_DRIVE")([0-9]+|$)"; then
        echo -e "${RED}[!] Destination drive $DST_DRIVE (or its partitions) is mounted! Please unmount before proceeding.${NC}"
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
    # Handle partition suffix for NVMe/mmc (e.g., /dev/nvme0n1p1)
    if [[ "$DST_DRIVE" =~ [0-9]$ ]]; then
        PART_PREFIX="${DST_DRIVE}p"
    else
        PART_PREFIX="$DST_DRIVE"
    fi
    DST_EFI="${PART_PREFIX}1"
    DST_ROOT="${PART_PREFIX}2"
    DST_EXFAT="${PART_PREFIX}3"
}

update_script() {
    echo -e "${BLUE}=== SELF-UPDATE ===${NC}"
    # Determine REPO_BASE from git remote if possible; fallback to env or placeholder
    REPO_BASE="${REPO_BASE:-}"
    if command -v git >/dev/null 2>&1; then
        ORIGIN_URL="$(git config --get remote.origin.url || true)"
        if [[ "$ORIGIN_URL" =~ ^git@github.com:([^/]+)/([^.]+)(\.git)?$ ]]; then
            G_USER="${BASH_REMATCH[1]}"; G_REPO="${BASH_REMATCH[2]}"
        elif [[ "$ORIGIN_URL" =~ ^https://github.com/([^/]+)/([^.]+)(\.git)?$ ]]; then
            G_USER="${BASH_REMATCH[1]}"; G_REPO="${BASH_REMATCH[2]}"
        fi
        if [[ -n "${G_USER:-}" && -n "${G_REPO:-}" ]]; then
            REPO_BASE="https://raw.githubusercontent.com/$G_USER/$G_REPO/main"
        fi
    fi
    REPO_BASE="${REPO_BASE:-https://raw.githubusercontent.com/yourusername/clone-ubuntu-os/main}"
    VERSION_URL="$REPO_BASE/VERSION"
    SCRIPT_URL="$REPO_BASE/clone_ubuntu_os_pv.sh"
    CHANGELOG_URL="$REPO_BASE/CHANGELOG.md"
    TMP_FILE="/tmp/clone_ubuntu_os_pv.sh"

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
    if ! [[ "$UBUNTU_SIZE" =~ ^[0-9]+$ ]] || [ "$UBUNTU_SIZE" -lt 16 ]; then
        echo -e "${RED}[!] Invalid size. Please enter an integer >= 16.${NC}"
        exit 1
    fi

    echo -e "${BLUE}[*] Installing required packages...${NC}"
    (sudo apt update && sudo apt install -y gparted rsync exfatprogs efibootmgr pv curl) &
    spinner $!

    echo -e "${BLUE}[*] Wiping partition table...${NC}"
    sudo wipefs -a $DST_DRIVE &
    spinner $!

    echo -e "${BLUE}[*] Creating partitions...${NC}"
    (sudo parted -s $DST_DRIVE mklabel gpt && sudo parted -s $DST_DRIVE mkpart EFI fat32 1MiB 513MiB && sudo parted -s $DST_DRIVE set 1 esp on && sudo parted -s $DST_DRIVE mkpart UBUNTU ext4 513MiB ${UBUNTU_SIZE}GiB && sudo parted -s $DST_DRIVE mkpart STORAGE ${UBUNTU_SIZE}GiB 100% && sudo partprobe $DST_DRIVE && sleep 2) &
    spinner $!

    echo -e "${BLUE}[*] Formatting partitions...${NC}"
    (sudo mkfs.vfat -F32 $DST_EFI && sudo mkfs.ext4 -F -L UBUNTU $DST_ROOT && sudo mkfs.exfat -n STORAGE $DST_EXFAT) &
    spinner $!

    echo -e "${BLUE}[*] Cloning root filesystem...${NC}"
    (sudo mkdir -p /mnt/src /mnt/dst &&     sudo mount $SRC_ROOT /mnt/src &&     sudo mount $DST_ROOT /mnt/dst &&     sudo rsync -aAXH --info=progress2 /mnt/src/ /mnt/dst/) &
    spinner $!

    if [[ -n "$SRC_EFI" ]]; then
        echo -e "${BLUE}[*] Cloning EFI partition...${NC}"
        (sudo mkdir -p /mnt/efi-old /mnt/efi-new && sudo mount $SRC_EFI /mnt/efi-old && sudo mount $DST_EFI /mnt/efi-new && sudo rsync -aAXH --info=progress2 /mnt/efi-old/ /mnt/efi-new/) &
        spinner $!
    else
        echo -e "${YELLOW}[!] No source EFI detected; creating fresh EFI only.${NC}"
        sudo mkdir -p /mnt/dst/boot/efi && sudo mount $DST_EFI /mnt/dst/boot/efi || true
    fi

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
    echo -e "${YELLOW}2) Show Status (drives, partitions, mounts)${NC}"
    echo -e "${YELLOW}3) Update Script (fetch latest version)${NC}"
    echo -e "${YELLOW}4) Exit${NC}"
    echo -e "${BLUE}=============================================${NC}"
    read -rp "Choose an option [1-4]: " choice
}

show_status() {
    echo -e "${BLUE}[*] Drives and partitions:${NC}"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL
    echo -e "${BLUE}[*] Mounted filesystems:${NC}"
    findmnt -rno SOURCE,TARGET | sort || true
}

while true; do
    menu
    case $choice in
        1) run_clone; break;;
        2) show_status;;
        3) update_script;;
        4) echo -e "${GREEN}Exiting.${NC}"; exit 0;;
        *) echo -e "${RED}Invalid choice, please select 1-4.${NC}";;
    esac
done

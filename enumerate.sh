#!/bin/bash

# ============================================
# Linux Privilege Escalation Checker
# Live Output - No Files Created
# Menjalankan semua command dan tampilkan langsung
# ============================================

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Counter untuk output
TOTAL_CMDS=0
CURRENT_CMDS=0

# Function untuk print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function untuk print subheader
print_subheader() {
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

# Function untuk menjalankan command dan tampilkan output
run_cmd() {
    local cmd="$1"
    local desc="$2"
    
    ((TOTAL_CMDS++))
    ((CURRENT_CMDS++))
    
    echo -e "\n${GREEN}[${CURRENT_CMDS}]${NC} ${YELLOW}$desc${NC}"
    echo -e "${MAGENTA}Command:${NC} $cmd"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    
    # Jalankan command dengan timeout 5 detik untuk mencegah hang
    timeout 5 bash -c "$cmd" 2>&1 | head -200
    
    # Jika output terlalu panjang, kasih warning
    local output_length=$(timeout 5 bash -c "$cmd" 2>&1 | wc -l)
    if [ $output_length -gt 200 ]; then
        echo -e "${YELLOW}[!] Output truncated (${output_length} lines total)${NC}"
    fi
    
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

# Function untuk menjalankan command dengan batasan
run_cmd_limited() {
    local cmd="$1"
    local desc="$2"
    local limit="$3"
    
    ((TOTAL_CMDS++))
    ((CURRENT_CMDS++))
    
    echo -e "\n${GREEN}[${CURRENT_CMDS}]${NC} ${YELLOW}$desc${NC}"
    echo -e "${MAGENTA}Command:${NC} $cmd"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    
    timeout 5 bash -c "$cmd" 2>&1 | head -$limit
    
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

# Function untuk check dan highlight hasil penting
run_cmd_highlight() {
    local cmd="$1"
    local desc="$2"
    local highlight="$3"
    
    ((TOTAL_CMDS++))
    ((CURRENT_CMDS++))
    
    echo -e "\n${GREEN}[${CURRENT_CMDS}]${NC} ${YELLOW}$desc${NC}"
    echo -e "${MAGENTA}Command:${NC} $cmd"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    
    # Jalankan command dan highlight pattern penting
    timeout 5 bash -c "$cmd" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qi "$highlight"; then
            echo -e "${RED}$line${NC}"
        else
            echo "$line"
        fi
    done | head -100
    
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

# Start script
clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║     Linux Privilege Escalation Enumeration - Live Output            ║"
echo "║                      No Files Created                                ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${GREEN}[*]${NC} Running enumeration at: $(date)"
echo -e "${GREEN}[*]${NC} User: $(whoami)"
echo -e "${GREEN}[*]${NC} Host: $(hostname)"
echo -e "${YELLOW}[!]${NC} This script does NOT create any files"
echo ""

# ============================================
# 1. Basic Info
# ============================================
print_header "1. BASIC SYSTEM INFORMATION"

run_cmd "id" "User and group IDs"
run_cmd "uname -a" "System information (kernel, hostname, architecture)"
run_cmd "hostname" "Hostname"
run_cmd "cat /etc/os-release 2>/dev/null" "OS release information"
run_cmd "env" "Environment variables"
run_cmd "pwd" "Current working directory"

# ============================================
# 2. User & Groups
# ============================================
print_header "2. USER & GROUP INFORMATION"

run_cmd "whoami" "Current user"
run_cmd "id" "User ID and group memberships"
run_cmd "groups" "Current user groups"
run_cmd "cat /etc/passwd | grep -v '/nologin\|/false' | head -30" "Active users (non-nologin)"
run_cmd "cat /etc/passwd | head -20" "All users (first 20)"
run_cmd "cat /etc/shadow 2>/dev/null | head -10" "Shadow file (first 10 lines)"
run_cmd "last | head -20" "Last logins"
run_cmd "w" "Currently logged in users"

# ============================================
# 3. SUID & SGID
# ============================================
print_header "3. SUID & SGID BINARIES"

run_cmd_limited "find / -type f -perm -04000 -ls 2>/dev/null | head -30" "SUID binaries (setuid root)" 30
run_cmd_limited "find / -type f -perm -02000 -ls 2>/dev/null | head -30" "SGID binaries (setgid)" 30
run_cmd_highlight "find / -perm -u=s -type f 2>/dev/null | head -30" "SUID binaries (alternative)" "nmap|vim|find|bash|python|perl|php|nc|netcat|socat"

# ============================================
# 4. Capabilities
# ============================================
print_header "4. CAPABILITIES"

run_cmd_limited "getcap -r / 2>/dev/null | head -30" "File capabilities (recursive)" 30
run_cmd_limited "find / -type f -executable -exec getcap {} \\; 2>/dev/null | head -30" "Executable capabilities" 30
run_cmd_limited "getcap /usr/bin/* /bin/* /sbin/* /usr/sbin/* 2>/dev/null | head -30" "Common binaries capabilities" 30

# ============================================
# 5. Cron Jobs
# ============================================
print_header "5. CRON JOBS"

run_cmd "cat /etc/crontab 2>/dev/null" "System crontab"
run_cmd "ls -la /etc/cron* 2>/dev/null" "Cron directories"
run_cmd "cat /etc/cron.d/* 2>/dev/null | head -30" "Cron.d files"
run_cmd "crontab -l 2>/dev/null" "Current user crontab"
run_cmd "ls -la /var/spool/cron/crontabs/ 2>/dev/null" "User crontabs"
run_cmd "cat /etc/anacrontab 2>/dev/null" "Anacrontab"

# ============================================
# 6. Process & Services
# ============================================
print_header "6. PROCESS & SERVICES"

run_cmd_limited "ps aux | grep ^root | head -20" "Root processes" 20
run_cmd_limited "ps aux | grep -v root | head -20" "Non-root processes" 20
run_cmd_limited "ps aux | grep -E 'python|perl|php|bash|sh' | head -20" "Script interpreter processes" 20
run_cmd_limited "lsof -i -n -P 2>/dev/null | head -30" "Network connections" 30
run_cmd "systemctl list-units --type=service --all 2>/dev/null | head -20" "Systemd services"
run_cmd "service --status-all 2>/dev/null | head -20" "SysV services"

# ============================================
# 7. Sudo
# ============================================
print_header "7. SUDO PRIVILEGES"

run_cmd_highlight "sudo -l 2>/dev/null" "Sudo privileges (current user)" "ALL|NOPASSWD|(root)"
run_cmd "sudo -n true 2>/dev/null && echo -e '${RED}[!] User can run sudo WITHOUT password!${NC}' || echo 'User needs password for sudo'" "Check sudo without password"

# ============================================
# 8. Writable Directories & Files
# ============================================
print_header "8. WRITABLE DIRECTORIES & FILES"

run_cmd_limited "find / -writable -type d 2>/dev/null | grep -v '/proc\|/sys\|/dev' | head -20" "Writable directories" 20
run_cmd_limited "find / -user root -perm -0002 -type f 2>/dev/null | head -20" "World writable root files" 20
run_cmd "ls -la /tmp /var/tmp /dev/shm 2>/dev/null" "World writable directories (common)"

# ============================================
# 9. Network Information
# ============================================
print_header "9. NETWORK INFORMATION"

run_cmd "ifconfig -a 2>/dev/null || ip addr show" "Network interfaces"
run_cmd "route -n 2>/dev/null || ip route show" "Routing table"
run_cmd "arp -a 2>/dev/null | head -15" "ARP table"
run_cmd "ss -tuln 2>/dev/null | head -20" "Listening ports"
run_cmd "netstat -tuln 2>/dev/null | head -20" "Netstat listening ports"

# ============================================
# 10. File System & Mounts
# ============================================
print_header "10. FILE SYSTEM & MOUNTS"

run_cmd "mount | head -20" "Mounted filesystems"
run_cmd "df -h | head -20" "Disk usage"
run_cmd "lsblk 2>/dev/null | head -20" "Block devices"

# ============================================
# 11. SSH & Keys
# ============================================
print_header "11. SSH & KEYS"

run_cmd "ls -la ~/.ssh/ 2>/dev/null" "Current user SSH directory"
run_cmd "find /home -name 'id_rsa' -o -name 'id_dsa' -o -name '*.pem' 2>/dev/null | head -15" "SSH keys"
run_cmd "cat ~/.ssh/authorized_keys 2>/dev/null" "Authorized keys"

# ============================================
# 12. History & Logs
# ============================================
print_header "12. HISTORY & LOGS"

run_cmd "tail -20 ~/.bash_history 2>/dev/null" "Last 20 bash history commands"
run_cmd "tail -10 /var/log/auth.log 2>/dev/null" "Last 10 auth log entries"
run_cmd "tail -10 /var/log/syslog 2>/dev/null" "Last 10 syslog entries"

# ============================================
# 13. Kernel & Modules
# ============================================
print_header "13. KERNEL & MODULES"

run_cmd "uname -a" "Kernel version"
run_cmd "lsmod | head -20" "Loaded kernel modules"
run_cmd "cat /proc/version" "Kernel version info"

# ============================================
# 14. Interesting Files
# ============================================
print_header "14. INTERESTING FILES"

run_cmd "find /home -name '.bashrc' -o -name '.profile' -o -name '.bash_profile' 2>/dev/null | head -10" "User config files"
run_cmd "find / -name '*.conf' -type f 2>/dev/null | grep -E 'apache|nginx|mysql|postgres|redis' | head -10" "Config files"
run_cmd "ls -la /etc/passwd /etc/shadow /etc/group /etc/sudoers 2>/dev/null" "Critical files permissions"

# ============================================
# 15. Docker & Containers (if any)
# ============================================
print_header "15. DOCKER & CONTAINERS"

run_cmd "docker ps 2>/dev/null" "Docker containers"
run_cmd "docker images 2>/dev/null" "Docker images"
run_cmd "groups | grep -i docker && echo -e '${RED}[!] User is in docker group!${NC}'" "Check docker group"

# ============================================
# Summary
# ============================================
print_header "ENUMERATION COMPLETE"

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                      ENUMERATION COMPLETE                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}[*]${NC} Total commands executed: ${TOTAL_CMDS}"
echo -e "${CYAN}[*]${NC} Completed at: $(date)"
echo -e "${CYAN}[*]${NC} User: $(whoami)"
echo -e "${CYAN}[*]${NC} Host: $(hostname)"
echo ""
echo -e "${YELLOW}[!]${NC} Important findings highlighted in ${RED}RED${NC}"
echo -e "${YELLOW}[!]${NC} Check for:"
echo -e "    • ${RED}SUID binaries${NC} like find, vim, python, bash"
echo -e "    • ${RED}Sudo without password${NC} (NOPASSWD)"
echo -e "    • ${RED}Writable directories${NC} in PATH"
echo -e "    • ${RED}Capabilities${NC} on binaries"
echo -e "    • ${RED}Cron jobs${NC} with writable scripts"
echo ""

# Optional: Ask user to save output
echo -e "${BLUE}Do you want to save this output to a file? (y/n)${NC}"
read -r save_choice
if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
    output_file="enum_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "${GREEN}[*]${NC} Saving output to: $output_file"
    script -q -c "$0" "$output_file" 2>/dev/null || echo "Please run script with 'script' command to save output"
fi

echo ""
echo -e "${GREEN}[✓] Done!${NC}"

#!/bin/sh

# ============================================
# Linux Privilege Escalation Checker
# POSIX Compliant - No Files Created
# Compatible with sh, bash, dash
# ============================================

# Warna (opsional, jika terminal support)
if [ -t 1 ]; then
    RED=$(printf '\033[0;31m')
    GREEN=$(printf '\033[0;32m')
    YELLOW=$(printf '\033[1;33m')
    BLUE=$(printf '\033[0;34m')
    CYAN=$(printf '\033[0;36m')
    NC=$(printf '\033[0m')
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; NC=''
fi

# Counter
CMD_COUNT=0

# Function untuk print header
print_header() {
    echo ""
    echo "${CYAN}============================================================${NC}"
    echo "${CYAN}$1${NC}"
    echo "${CYAN}============================================================${NC}"
    echo ""
}

# Function untuk print subheader
print_subheader() {
    echo ""
    echo "${BLUE}------------------------------------------------------------${NC}"
    echo "${BLUE}>>> $1${NC}"
    echo "${BLUE}------------------------------------------------------------${NC}"
}

# Function untuk menjalankan command
run_cmd() {
    cmd="$1"
    desc="$2"
    
    CMD_COUNT=$((CMD_COUNT + 1))
    
    echo ""
    echo "${GREEN}[${CMD_COUNT}]${NC} ${YELLOW}${desc}${NC}"
    echo "${BLUE}Command:${NC} ${cmd}"
    echo "${BLUE}------------------------------------------------------------${NC}"
    
    # Jalankan command dengan timeout jika ada
    if command -v timeout >/dev/null 2>&1; then
        timeout 10 sh -c "$cmd" 2>&1 | head -100
    else
        sh -c "$cmd" 2>&1 | head -100
    fi
    
    echo "${BLUE}------------------------------------------------------------${NC}"
}

# Function untuk run command dengan limit
run_cmd_limited() {
    cmd="$1"
    desc="$2"
    limit="$3"
    
    CMD_COUNT=$((CMD_COUNT + 1))
    
    echo ""
    echo "${GREEN}[${CMD_COUNT}]${NC} ${YELLOW}${desc}${NC}"
    echo "${BLUE}Command:${NC} ${cmd}"
    echo "${BLUE}------------------------------------------------------------${NC}"
    
    if command -v timeout >/dev/null 2>&1; then
        timeout 10 sh -c "$cmd" 2>&1 | head -"$limit"
    else
        sh -c "$cmd" 2>&1 | head -"$limit"
    fi
    
    echo "${BLUE}------------------------------------------------------------${NC}"
}

# Start
printf "%s\n" "${CYAN}============================================================"
printf "%s\n" "     Linux Privilege Escalation Enumeration - Live"
printf "%s\n" "                  No Files Created"
printf "%s\n" "============================================================${NC}"
echo ""

printf "%s\n" "${GREEN}[*]${NC} Started at: $(date)"
printf "%s\n" "${GREEN}[*]${NC} User: $(whoami 2>/dev/null || echo 'unknown')"
printf "%s\n" "${GREEN}[*]${NC} Host: $(hostname 2>/dev/null || echo 'unknown')"
printf "%s\n" "${YELLOW}[!]${NC} This script does NOT create any files"
echo ""

# ============================================
# 1. Basic Info
# ============================================
print_header "1. BASIC SYSTEM INFORMATION"

run_cmd "id" "User and group IDs"
run_cmd "uname -a" "System information"
run_cmd "hostname" "Hostname"
run_cmd "cat /etc/os-release 2>/dev/null || cat /etc/issue 2>/dev/null" "OS release"
run_cmd "env" "Environment variables"
run_cmd "pwd" "Current working directory"

# ============================================
# 2. User & Groups
# ============================================
print_header "2. USER & GROUP INFORMATION"

run_cmd "whoami" "Current user"
run_cmd "id" "User ID and groups"
run_cmd "groups" "Current user groups"
run_cmd "cat /etc/passwd 2>/dev/null | grep -v '/nologin\|/false' | head -30" "Active users"
run_cmd "cat /etc/passwd 2>/dev/null | head -20" "All users (first 20)"
run_cmd "last 2>/dev/null | head -15" "Last logins"
run_cmd "w 2>/dev/null" "Currently logged in users"

# ============================================
# 3. SUID & SGID
# ============================================
print_header "3. SUID & SGID BINARIES"

run_cmd_limited "find / -type f -perm -04000 -ls 2>/dev/null | head -30" "SUID binaries" 30
run_cmd_limited "find / -type f -perm -02000 -ls 2>/dev/null | head -30" "SGID binaries" 30
run_cmd_limited "find / -perm -u=s -type f 2>/dev/null | head -30" "SUID alternative" 30

# ============================================
# 4. Capabilities
# ============================================
print_header "4. CAPABILITIES"

run_cmd_limited "getcap -r / 2>/dev/null | head -30" "File capabilities" 30
run_cmd_limited "getcap /usr/bin/* /bin/* /sbin/* /usr/sbin/* 2>/dev/null | head -30" "Common binaries capabilities" 30

# ============================================
# 5. Cron Jobs
# ============================================
print_header "5. CRON JOBS"

run_cmd "cat /etc/crontab 2>/dev/null" "System crontab"
run_cmd "ls -la /etc/cron* 2>/dev/null | head -30" "Cron directories"
run_cmd "cat /etc/cron.d/* 2>/dev/null | head -30" "Cron.d files"
run_cmd "crontab -l 2>/dev/null" "Current user crontab"
run_cmd "ls -la /var/spool/cron/crontabs/ 2>/dev/null" "User crontabs"

# ============================================
# 6. Process & Services
# ============================================
print_header "6. PROCESS & SERVICES"

run_cmd_limited "ps aux 2>/dev/null | grep '^root' | head -20" "Root processes" 20
run_cmd_limited "ps aux 2>/dev/null | grep -v '^root' | head -20" "Non-root processes" 20
run_cmd_limited "ps aux 2>/dev/null | grep -E 'python|perl|php|bash|sh' | head -20" "Script processes" 20
run_cmd_limited "lsof -i -n -P 2>/dev/null | head -20" "Network connections" 20
run_cmd_limited "systemctl list-units --type=service --all 2>/dev/null | head -20" "Systemd services" 20
run_cmd_limited "service --status-all 2>/dev/null | head -20" "SysV services" 20

# ============================================
# 7. Sudo
# ============================================
print_header "7. SUDO PRIVILEGES"

run_cmd "sudo -l 2>/dev/null" "Sudo privileges"

# Check sudo without password
echo ""
echo "${GREEN}[$((CMD_COUNT + 1))]${NC} ${YELLOW}Check sudo without password${NC}"
echo "${BLUE}------------------------------------------------------------${NC}"
if sudo -n true 2>/dev/null; then
    echo "${RED}[!] User can run sudo WITHOUT password!${NC}"
else
    echo "User needs password for sudo"
fi
echo "${BLUE}------------------------------------------------------------${NC}"
CMD_COUNT=$((CMD_COUNT + 1))

# ============================================
# 8. Writable Directories
# ============================================
print_header "8. WRITABLE DIRECTORIES & FILES"

run_cmd_limited "find / -writable -type d 2>/dev/null | grep -v '/proc\|/sys\|/dev' | head -20" "Writable directories" 20
run_cmd_limited "find / -user root -perm -0002 -type f 2>/dev/null | head -20" "World writable root files" 20
run_cmd "ls -la /tmp /var/tmp /dev/shm 2>/dev/null" "World writable directories"

# ============================================
# 9. Network Information
# ============================================
print_header "9. NETWORK INFORMATION"

run_cmd "ip addr show 2>/dev/null || ifconfig -a 2>/dev/null" "Network interfaces"
run_cmd "ip route show 2>/dev/null || route -n 2>/dev/null" "Routing table"
run_cmd_limited "ss -tuln 2>/dev/null | head -20" "Listening ports" 20
run_cmd_limited "netstat -tuln 2>/dev/null | head -20" "Netstat listening" 20

# ============================================
# 10. File System & Mounts
# ============================================
print_header "10. FILE SYSTEM & MOUNTS"

run_cmd_limited "mount 2>/dev/null | head -20" "Mounted filesystems" 20
run_cmd_limited "df -h 2>/dev/null | head -20" "Disk usage" 20
run_cmd_limited "lsblk 2>/dev/null | head -20" "Block devices" 20

# ============================================
# 11. SSH & Keys
# ============================================
print_header "11. SSH & KEYS"

run_cmd "ls -la ~/.ssh/ 2>/dev/null" "Current user SSH directory"
run_cmd_limited "find /home -name 'id_rsa' -o -name 'id_dsa' -o -name '*.pem' 2>/dev/null | head -15" "SSH keys" 15
run_cmd "cat ~/.ssh/authorized_keys 2>/dev/null" "Authorized keys"

# ============================================
# 12. History & Logs
# ============================================
print_header "12. HISTORY & LOGS"

run_cmd "tail -20 ~/.bash_history 2>/dev/null" "Last 20 bash history"
run_cmd "tail -10 /var/log/auth.log 2>/dev/null" "Last 10 auth log"
run_cmd "tail -10 /var/log/syslog 2>/dev/null" "Last 10 syslog"

# ============================================
# 13. Kernel & Modules
# ============================================
print_header "13. KERNEL & MODULES"

run_cmd "uname -a" "Kernel version"
run_cmd_limited "lsmod 2>/dev/null | head -20" "Loaded kernel modules" 20
run_cmd "cat /proc/version 2>/dev/null" "Kernel version info"

# ============================================
# 14. Interesting Files
# ============================================
print_header "14. INTERESTING FILES"

run_cmd_limited "find /home -name '.bashrc' -o -name '.profile' -o -name '.bash_profile' 2>/dev/null | head -10" "User config files" 10
run_cmd_limited "find / -name '*.conf' -type f 2>/dev/null | grep -E 'apache|nginx|mysql|postgres|redis' | head -10" "Config files" 10
run_cmd "ls -la /etc/passwd /etc/shadow /etc/group /etc/sudoers 2>/dev/null" "Critical files permissions"

# ============================================
# 15. Docker & Containers
# ============================================
print_header "15. DOCKER & CONTAINERS"

run_cmd "docker ps 2>/dev/null" "Docker containers"
run_cmd "docker images 2>/dev/null" "Docker images"

# Check docker group
echo ""
echo "${GREEN}[$((CMD_COUNT + 1))]${NC} ${YELLOW}Check docker group membership${NC}"
echo "${BLUE}------------------------------------------------------------${NC}"
if groups 2>/dev/null | grep -q docker; then
    echo "${RED}[!] User is in docker group!${NC}"
else
    echo "User is not in docker group"
fi
echo "${BLUE}------------------------------------------------------------${NC}"
CMD_COUNT=$((CMD_COUNT + 1))

# ============================================
# Summary
# ============================================
print_header "ENUMERATION COMPLETE"

echo "${CYAN}============================================================${NC}"
echo "${CYAN}                      ENUMERATION COMPLETE                    ${NC}"
echo "${CYAN}============================================================${NC}"
echo ""
echo "${GREEN}[*]${NC} Total commands executed: ${CMD_COUNT}"
echo "${GREEN}[*]${NC} Completed at: $(date)"
echo "${GREEN}[*]${NC} User: $(whoami 2>/dev/null || echo 'unknown')"
echo "${GREEN}[*]${NC} Host: $(hostname 2>/dev/null || echo 'unknown')"
echo ""
echo "${YELLOW}[!]${NC} Check for privilege escalation vectors:"
echo "    • SUID binaries (find, vim, python, bash, etc)"
echo "    • Sudo without password (NOPASSWD)"
echo "    • Writable directories in PATH"
echo "    • Capabilities on binaries"
echo "    • Cron jobs with writable scripts"
echo "    • Writable /etc/passwd or /etc/shadow"
echo ""

echo "${GREEN}[✓] Done!${NC}"

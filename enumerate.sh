#!/bin/sh
# ============================================
# Privilege Escalation Checker
# Based on xk4njut Dark Ai Cheatsheet
# ============================================

# Warna
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

print_header() {
    echo ""
    printf "%s\n" "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    printf "%s\n" "${CYAN}║ $1${NC}"
    printf "%s\n" "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_cmd() {
    CMD_COUNT=$((CMD_COUNT + 1))
    echo ""
    printf "%s\n" "${GREEN}[$CMD_COUNT]${NC} ${YELLOW}$2${NC}"
    printf "%s\n" "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
    printf "%s\n" "${BLUE}│ Command:${NC} $1"
    printf "%s\n" "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
    
    # Run command
    if command -v timeout >/dev/null 2>&1; then
        timeout 15 sh -c "$1" 2>&1 | head -50
    else
        sh -c "$1" 2>&1 | head -50
    fi
    echo ""
}

# ============================================
# START
# ============================================
printf "%s\n" "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
printf "%s\n" "${CYAN}║           PRIVILEGE ESCALATION CHECKER                           ║${NC}"
printf "%s\n" "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

printf "%s\n" "${GREEN}[*]${NC} Started: $(date)"
printf "%s\n" "${GREEN}[*]${NC} User: $(whoami 2>/dev/null || echo 'unknown')"
printf "%s\n" "${GREEN}[*]${NC} Host: $(hostname 2>/dev/null || echo 'unknown')"
echo ""

# ============================================
# 1. Basic Info
# ============================================
print_header "1. BASIC INFORMATION"

print_cmd "id" "User and group IDs"
print_cmd "uname -a" "System information"
print_cmd "hostname" "Hostname"
print_cmd "cat /etc/os-release 2>/dev/null" "OS release"

# ============================================
# 2. User & Groups
# ============================================
print_header "2. USER & GROUP INFORMATION"

print_cmd "whoami" "Current user"
print_cmd "id" "User ID and groups"
print_cmd "groups" "Current user groups"
print_cmd "cat /etc/passwd 2>/dev/null | grep -v '/nologin\|/false'" "Active users (with shell)"
print_cmd "cat /etc/shadow 2>/dev/null | head -20" "Shadow file (first 20 lines)"

# ============================================
# 3. Sudo & SUID
# ============================================
print_header "3. SUDO & SUID BINARIES"

print_cmd "sudo -l 2>/dev/null" "Sudo privileges"
print_cmd "find / -type f -perm -04000 -ls 2>/dev/null | head -30" "SUID binaries"
print_cmd "find / -type f -perm -02000 -ls 2>/dev/null | head -30" "SGID binaries"
print_cmd "find / -perm -u=s -type f 2>/dev/null | head -30" "SUID alternative"

# ============================================
# 4. Capabilities
# ============================================
print_header "4. CAPABILITIES"

print_cmd "getcap -r / 2>/dev/null | head -30" "Recursive capabilities"
print_cmd "find / -type f -exec getcap {} \\; 2>/dev/null | head -30" "Find with getcap"
print_cmd "find / -type f -executable -exec getcap {} \\; 2>/dev/null | head -30" "Executable capabilities"
print_cmd "getcap /usr/bin/* /bin/* /sbin/* /usr/sbin/* /usr/local/bin/* 2>/dev/null | head -30" "Common binaries"

# ============================================
# 5. Cron Jobs
# ============================================
print_header "5. CRON JOBS"

print_cmd "cat /etc/crontab 2>/dev/null" "System crontab"
print_cmd "ls -la /etc/cron* 2>/dev/null" "Cron directories"
print_cmd "cat /etc/cron.d/* 2>/dev/null | head -30" "Cron.d files"
print_cmd "cat /var/spool/cron/crontabs/* 2>/dev/null" "User crontabs (crontabs)"
print_cmd "cat /var/spool/cron/* 2>/dev/null" "User crontabs (spool)"

# ============================================
# 6. Process & Services
# ============================================
print_header "6. PROCESS & SERVICES"

print_cmd "ps aux 2>/dev/null | grep '^root' | head -20" "Root processes"
print_cmd "ps aux 2>/dev/null | grep -v '^root' | head -20" "Non-root processes"
print_cmd "ps aux 2>/dev/null | grep -E 'python|perl|php|bash|sh' | head -20" "Script processes"
print_cmd "lsof -i -n -P 2>/dev/null | head -20" "Network connections"

# ============================================
# 7. Web Server Config
# ============================================
print_header "7. WEB SERVER CONFIGURATIONS"

print_cmd "grep -r 'DocumentRoot' /etc/apache2/ 2>/dev/null | grep -v '#' | head -20" "Apache DocumentRoot"
print_cmd "grep -r 'root' /etc/nginx/ 2>/dev/null | grep -v '#' | head -20" "Nginx config"
print_cmd "find /var/www -type f -name '*.php' -o -name 'config*.php' -o -name 'wp-config.php' 2>/dev/null | head -20" "PHP config files"

# ============================================
# 8. Additional Checks
# ============================================
print_header "8. ADDITIONAL CHECKS"

print_cmd "find / -writable -type d 2>/dev/null | grep -v '/proc\|/sys\|/dev' | head -20" "Writable directories"
print_cmd "find / -user root -perm -0002 -type f 2>/dev/null | head -20" "World writable root files"
print_cmd "ls -la /etc/passwd /etc/shadow /etc/sudoers 2>/dev/null" "Critical file permissions"
print_cmd "env | grep -i 'path\|home\|user' 2>/dev/null" "Environment variables"

# ============================================
# Summary
# ============================================
echo ""
printf "%s\n" "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
printf "%s\n" "${CYAN}║                      SCAN COMPLETE                               ║${NC}"
printf "%s\n" "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
printf "%s\n" "${GREEN}[*]${NC} Total commands executed: $CMD_COUNT"
printf "%s\n" "${GREEN}[*]${NC} Completed at: $(date)"
echo ""
printf "%s\n" "${YELLOW}[!]${NC} Quick privilege escalation checks:"
echo "    • Check SUID binaries: find / -perm -4000 -type f 2>/dev/null"
echo "    • Check sudo: sudo -l"
echo "    • Check writable files: find / -writable -type f 2>/dev/null"
echo "    • Check capabilities: getcap -r / 2>/dev/null"
echo ""
printf "%s\n" "${GREEN}[✓] Done!${NC}"

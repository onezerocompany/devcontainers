#!/usr/bin/env bash

set -e

ASCII_LOGO="${ASCII_LOGO}"
INFO="${INFO}"
MESSAGE="${MESSAGE}"
ENABLE="${ENABLE}"

USERNAME="${USERNAME:-${_REMOTE_USER:-root}}"

if [ "${ENABLE}" != "true" ]; then
    echo "OneZero MOTD is disabled. Skipping installation."
    exit 0
fi

echo "Installing OneZero MOTD..."

# Create the MOTD script directory
mkdir -p /etc/update-motd.d

# Create a config file to store the customizable values
mkdir -p /etc/onezero
cat > /etc/onezero/motd.conf << EOF
# OneZero MOTD Configuration
ASCII_LOGO="${ASCII_LOGO}"
INFO="${INFO}"
MESSAGE="${MESSAGE}"
EOF

# Write the MOTD script that reads config at runtime
cat > /etc/update-motd.d/50-onezero << 'MOTD_SCRIPT'
#!/bin/bash

# Clear default MOTD if it exists
[ -f /etc/motd ] && > /etc/motd

# Load configuration
if [ -f /etc/onezero/motd.conf ]; then
    source /etc/onezero/motd.conf
fi

# Default values if not set
ASCII_LOGO="${ASCII_LOGO:-   ____              _____              
  / __ \\            |__  /              
 | |  | |_ __   ___   / / ___ _ __ ___  
 | |  | | '_ \\ / _ \\ / / / _ \\ '__/ _ \\ 
 | |__| | | | |  __// /_|  __/ | | (_) |
  \\____/|_| |_|\\___/____|\\___|_|  \\___/ }"
INFO="${INFO:-Welcome to OneZero Development Container}"
MESSAGE="${MESSAGE:-Happy coding!}"

# ANSI color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Display ASCII logo
printf "${BLUE}"
printf '%s\n' "${ASCII_LOGO}"
printf "${RESET}\n"

# Display info
printf "${GREEN}%s${RESET}\n\n" "${INFO}"

# Display system information
printf "${CYAN}System Information:${RESET}\n"
printf "  Date: %s\n" "$(date)"

# Get CPU info
if [ -f /proc/cpuinfo ]; then
    CPU_MODEL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | sed 's/^ *//')
    CPU_CORES=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "0")
    if [ -n "${CPU_MODEL}" ] || [ "${CPU_CORES}" != "0" ]; then
        printf "  CPU: %s (%d cores)\n" "${CPU_MODEL:-Unknown}" "${CPU_CORES}"
    fi
elif command -v sysctl &> /dev/null && sysctl -n machdep.cpu.brand_string &> /dev/null 2>&1; then
    # macOS
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    CPU_CORES=$(sysctl -n hw.logicalcpu 2>/dev/null)
    if [ -n "${CPU_MODEL}" ] && [ -n "${CPU_CORES}" ]; then
        printf "  CPU: %s (%d cores)\n" "${CPU_MODEL}" "${CPU_CORES}"
    fi
elif command -v nproc &> /dev/null; then
    # Fallback to nproc for core count
    CPU_CORES=$(nproc 2>/dev/null)
    if [ -n "${CPU_CORES}" ]; then
        printf "  CPU: Unknown (%s cores)\n" "${CPU_CORES}"
    fi
fi

# Check for memory info (may not be available in all environments)
if command -v free &> /dev/null; then
    MEM_INFO=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}')
    if [ -n "${MEM_INFO}" ]; then
        printf "  Memory: %s\n" "${MEM_INFO}"
    fi
elif [ -f /proc/meminfo ]; then
    # Fallback to /proc/meminfo if free is not available
    MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    MEM_AVAILABLE_KB=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [ -n "${MEM_TOTAL_KB}" ] && [ -n "${MEM_AVAILABLE_KB}" ]; then
        MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAILABLE_KB))
        MEM_TOTAL_MB=$((MEM_TOTAL_KB / 1024))
        MEM_USED_MB=$((MEM_USED_KB / 1024))
        printf "  Memory: %dM / %dM\n" "${MEM_USED_MB}" "${MEM_TOTAL_MB}"
    fi
elif command -v vm_stat &> /dev/null; then
    # macOS - show used/total memory
    PAGE_SIZE=$(sysctl -n hw.pagesize 2>/dev/null)
    MEM_TOTAL=$(sysctl -n hw.memsize 2>/dev/null)
    
    if [ -n "${PAGE_SIZE}" ] && [ -n "${MEM_TOTAL}" ]; then
        VM_STAT=$(vm_stat 2>/dev/null)
        PAGES_FREE=$(echo "$VM_STAT" | awk '/Pages free/ {print $3}' | sed 's/\.//')
        PAGES_ACTIVE=$(echo "$VM_STAT" | awk '/Pages active/ {print $3}' | sed 's/\.//')
        PAGES_INACTIVE=$(echo "$VM_STAT" | awk '/Pages inactive/ {print $3}' | sed 's/\.//')
        PAGES_SPECULATIVE=$(echo "$VM_STAT" | awk '/Pages speculative/ {print $3}' | sed 's/\.//')
        PAGES_WIRED=$(echo "$VM_STAT" | awk '/Pages wired/ {print $4}' | sed 's/\.//')
        
        if [ -n "${PAGES_ACTIVE}" ] && [ -n "${PAGES_WIRED}" ]; then
            MEM_USED=$(( (${PAGES_ACTIVE:-0} + ${PAGES_INACTIVE:-0} + ${PAGES_SPECULATIVE:-0} + ${PAGES_WIRED:-0}) * PAGE_SIZE ))
            MEM_TOTAL_GB=$(echo "scale=1; $MEM_TOTAL / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
            MEM_USED_GB=$(echo "scale=1; $MEM_USED / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
            
            if [ "${MEM_TOTAL_GB}" != "N/A" ] && [ "${MEM_USED_GB}" != "N/A" ]; then
                printf "  Memory: %sG / %sG\n" "${MEM_USED_GB}" "${MEM_TOTAL_GB}"
            fi
        fi
    fi
fi

# Get storage info
if command -v df &> /dev/null; then
    # Get root filesystem usage
    STORAGE_INFO=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')
    if [ -n "${STORAGE_INFO}" ]; then
        printf "  Storage: %s\n" "${STORAGE_INFO}"
    fi
fi

printf "\n"

# Display message
printf "${YELLOW}%s${RESET}\n\n" "${MESSAGE}"
MOTD_SCRIPT

# Make the script executable
chmod +x /etc/update-motd.d/50-onezero

# Disable other MOTD scripts on Ubuntu/Debian
if [ -d /etc/update-motd.d ]; then
    for file in /etc/update-motd.d/*; do
        if [ "$(basename "$file")" != "50-onezero" ] && [ -x "$file" ]; then
            chmod -x "$file" 2>/dev/null || true
        fi
    done
fi

# Configure SSH to show MOTD
if [ -f /etc/ssh/sshd_config ]; then
    # Use a more portable approach
    grep -v "^#*PrintMotd" /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp 2>/dev/null || true
    echo "PrintMotd yes" >> /etc/ssh/sshd_config.tmp
    mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config 2>/dev/null || true
fi

# Test the MOTD
echo "Testing OneZero MOTD:"
echo "===================="
/etc/update-motd.d/50-onezero

echo "OneZero MOTD installed successfully!"
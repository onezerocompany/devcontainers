#!/bin/bash

# Modern Shell MOTD Display Script

# ANSI color codes
PURPLE='\033[35m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'
BOLD='\033[1m'

# Display ASCII art banner
printf "\n${PURPLE} ██████╗ ███╗   ██╗███████╗███████╗███████╗██████╗  ██████╗ 
██╔═══██╗████╗  ██║██╔════╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
██║   ██║██╔██╗ ██║█████╗    ███╔╝ █████╗  ██████╔╝██║   ██║
██║   ██║██║╚██╗██║██╔══╝   ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
╚██████╔╝██║ ╚████║███████╗███████╗███████╗██║  ██║╚██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝${RESET}\n"

# System information
printf "\n${BOLD}${CYAN}System Information:${RESET}\n"
printf "  ${GREEN}Hostname:${RESET} $(hostname)\n"
printf "  ${GREEN}Kernel:${RESET} $(uname -r)\n"
printf "  ${GREEN}Shell:${RESET} $SHELL\n"

# Container information (if in container)
if [ -f /.dockerenv ] || [ -n "$DEVCONTAINER" ]; then
    printf "\n${BOLD}${BLUE}Container Environment:${RESET}\n"
    printf "  ${GREEN}Container:${RESET} Yes\n"
    if [ -n "$DEVCONTAINER_METADATA" ]; then
        printf "  ${GREEN}Dev Container:${RESET} Yes\n"
    fi
fi

# Modern tools status
printf "\n${BOLD}${YELLOW}Modern Shell Tools:${RESET}\n"

# Check for installed tools
check_tool() {
    local tool=$1
    local display_name=$2
    local aliases=$3
    if command -v "$tool" &> /dev/null; then
        printf "  ${GREEN}✓${RESET} $display_name"
        if [ -n "$aliases" ]; then
            printf " ${CYAN}[$aliases]${RESET}"
        fi
        printf "\n"
    else
        printf "  ${YELLOW}✗${RESET} $display_name (not installed)\n"
    fi
}

check_tool "mise" "Mise" "tools"
check_tool "starship" "Starship Prompt"
check_tool "zoxide" "Zoxide" "z, zi"
check_tool "eza" "Eza" "ls, ll, la, lt, tree"
check_tool "bat" "Bat" "cat"

# Final message
printf "\n${CYAN}Ready to code! 🚀${RESET}\n\n"
#!/bin/bash
set -e

# ========================================
# MOTD CONFIGURATION
# ========================================

# Function to install MOTD script
install_motd() {
    local user_home="$1"
    local custom_text="$2"
    
    mkdir -p "$user_home/.config"
    
    # Create the MOTD script with custom or default content
    if [ -n "$custom_text" ]; then
        # Create custom MOTD
        cat > "$user_home/.config/modern-shell-motd.sh" << EOF
#!/bin/bash

# Colors
GREEN='\033[32m'
CYAN='\033[36m'
RESET='\033[0m'

# Display custom message
printf "\n\${CYAN}$custom_text\${RESET}\n\n"

# Simple tools display
printf "\${GREEN}Tools:\${RESET} "

# Check and display available tools
tools_found=""
command -v mise >/dev/null && tools_found="\${tools_found}mise "
command -v starship >/dev/null && tools_found="\${tools_found}starship "
command -v zoxide >/dev/null && tools_found="\${tools_found}zoxide "
command -v eza >/dev/null && tools_found="\${tools_found}eza "
command -v bat >/dev/null && tools_found="\${tools_found}bat "

printf "\${GREEN}\${tools_found:-none}\${RESET}\n"
printf "\n\${CYAN}Ready to code! 🚀\${RESET}\n\n"
EOF
    else
        # Create default OneZero MOTD
        cat > "$user_home/.config/modern-shell-motd.sh" << 'MOTD_SCRIPT'
#!/bin/bash

# Colors
PURPLE='\033[35m'
GREEN='\033[32m'
CYAN='\033[36m'
RESET='\033[0m'

# Display ASCII art banner
printf "\n${PURPLE} ██████╗ ███╗   ██╗███████╗███████╗███████╗██████╗  ██████╗ 
██╔═══██╗████╗  ██║██╔════╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
██║   ██║██╔██╗ ██║█████╗    ███╔╝ █████╗  ██████╔╝██║   ██║
██║   ██║██║╚██╗██║██╔══╝   ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
╚██████╔╝██║ ╚████║███████╗███████╗███████╗██║  ██║╚██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝${RESET}\n"

# Simple tools display
printf "${GREEN}Tools:${RESET} "

# Check and display available tools
tools_found=""
command -v mise >/dev/null && tools_found="${tools_found}mise "
command -v starship >/dev/null && tools_found="${tools_found}starship "
command -v zoxide >/dev/null && tools_found="${tools_found}zoxide "
command -v eza >/dev/null && tools_found="${tools_found}eza "
command -v bat >/dev/null && tools_found="${tools_found}bat "

printf "${GREEN}${tools_found:-none}${RESET}\n"
printf "\n${CYAN}Ready to code! 🚀${RESET}\n\n"
MOTD_SCRIPT
    fi

    chmod +x "$user_home/.config/modern-shell-motd.sh"
    echo "  Installed MOTD script"
}

# Get MOTD display content for template replacement
get_motd_display() {
    echo "[ -f ~/.config/modern-shell-motd.sh ] && ~/.config/modern-shell-motd.sh"
}
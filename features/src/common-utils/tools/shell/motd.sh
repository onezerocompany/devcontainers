#!/bin/bash
set -e

# ========================================
# MOTD CONFIGURATION
# ========================================

# Function to install MOTD script
install_motd() {
    local user_home="$1"
    local logo="${2:-onezero}"
    local instructions="${3:-}"
    local notice="${4:-}"
    
    mkdir -p "$user_home/.config"
    
    # Start building the MOTD script
    cat > "$user_home/.config/modern-shell-motd.sh" << 'MOTD_HEADER'
#!/bin/bash

# Colors
PURPLE='\033[35m'
GREEN='\033[32m'
CYAN='\033[36m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
BOLD='\033[1m'
RESET='\033[0m'
MOTD_HEADER

    # Add logo section based on selection
    if [ "$logo" = "onezero" ]; then
        cat >> "$user_home/.config/modern-shell-motd.sh" << 'ONEZERO_LOGO'

# OneZero ASCII Logo
printf "\n${PURPLE} ██████╗ ███╗   ██╗███████╗███████╗███████╗██████╗  ██████╗ 
██╔═══██╗████╗  ██║██╔════╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
██║   ██║██╔██╗ ██║█████╗    ███╔╝ █████╗  ██████╔╝██║   ██║
██║   ██║██║╚██╗██║██╔══╝   ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
╚██████╔╝██║ ╚████║███████╗███████╗███████╗██║  ██║╚██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝${RESET}\n"
ONEZERO_LOGO
    elif [ "$logo" = "docker" ]; then
        cat >> "$user_home/.config/modern-shell-motd.sh" << 'DOCKER_LOGO'

# Docker ASCII Logo
printf "\n${CYAN}      ##         .
## ## ##        ==
## ## ## ## ##    ===
/\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"___/ ===
~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
     \\______ o          __/
      \\    \\        __/
       \\____\\______/${RESET}\n"
printf "${BLUE}${BOLD}    D O C K E R${RESET}\n"
DOCKER_LOGO
    elif [ "$logo" = "kubernetes" ]; then
        cat >> "$user_home/.config/modern-shell-motd.sh" << 'K8S_LOGO'

# Kubernetes ASCII Logo  
printf "\n${BLUE}    ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈
  ⎈                       ⎈
⎈     K U B E R N E T E S     ⎈
  ⎈                       ⎈
    ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈${RESET}\n"
K8S_LOGO
    elif [ "$logo" = "dev" ]; then
        cat >> "$user_home/.config/modern-shell-motd.sh" << 'DEV_LOGO'

# Dev ASCII Logo
printf "\n${GREEN}╔═══════════════════════════════════╗
║                                   ║
║         🚀 DEV CONTAINER 🚀        ║
║                                   ║
╚═══════════════════════════════════╝${RESET}\n"
DEV_LOGO
    elif [ "$logo" != "none" ] && [ -n "$logo" ]; then
        # Custom logo - escape any single quotes and insert it
        escaped_logo=$(echo "$logo" | sed "s/'/'\\\\''/g")
        cat >> "$user_home/.config/modern-shell-motd.sh" << EOF

# Custom Logo
printf "\n\${CYAN}$escaped_logo\${RESET}\n"
EOF
    fi

    # Add notice section if provided
    if [ -n "$notice" ]; then
        escaped_notice=$(echo "$notice" | sed "s/'/'\\\\''/g")
        cat >> "$user_home/.config/modern-shell-motd.sh" << EOF

# Notice
printf "\n\${RED}${BOLD}⚠️  NOTICE:\${RESET} \${YELLOW}$escaped_notice\${RESET}\n"
EOF
    fi

    # Add instructions section if provided  
    if [ -n "$instructions" ]; then
        escaped_instructions=$(echo "$instructions" | sed "s/'/'\\\\''/g")
        cat >> "$user_home/.config/modern-shell-motd.sh" << EOF

# Instructions
printf "\n\${BLUE}${BOLD}📋 INSTRUCTIONS:\${RESET}\n"
printf "\${CYAN}$escaped_instructions\${RESET}\n"
EOF
    fi

    # Add tools detection section
    cat >> "$user_home/.config/modern-shell-motd.sh" << 'TOOLS_SECTION'

# Tools detection and display
printf "\n${GREEN}${BOLD}🔧 TOOLS:${RESET} "

# Check and display available tools
tools_found=""
command -v mise >/dev/null && tools_found="${tools_found}mise "
command -v starship >/dev/null && tools_found="${tools_found}starship "
command -v zoxide >/dev/null && tools_found="${tools_found}zoxide "
command -v eza >/dev/null && tools_found="${tools_found}eza "
command -v bat >/dev/null && tools_found="${tools_found}bat "
command -v kubectl >/dev/null && tools_found="${tools_found}kubectl "
command -v helm >/dev/null && tools_found="${tools_found}helm "
command -v flux >/dev/null && tools_found="${tools_found}flux "
command -v docker >/dev/null && tools_found="${tools_found}docker "
command -v docker-compose >/dev/null && tools_found="${tools_found}compose "

if [ -n "$tools_found" ]; then
    printf "${GREEN}${tools_found}${RESET}\n"
else
    printf "${YELLOW}basic setup${RESET}\n"
fi

# Container info
if [ -f "/.dockerenv" ] || [ -n "${DEVCONTAINER:-}" ]; then
    printf "${BLUE}${BOLD}📦 CONTAINER:${RESET} "
    if [ -n "${DEVCONTAINER_NAME:-}" ]; then
        printf "${CYAN}${DEVCONTAINER_NAME}${RESET}"
    elif [ -n "${CODESPACE_NAME:-}" ]; then
        printf "${CYAN}GitHub Codespace${RESET}"
    else
        printf "${CYAN}Development Container${RESET}"
    fi
    printf "\n"
fi

# Ready message
printf "\n${GREEN}${BOLD}✨ Ready to code!${RESET} 🚀\n\n"
TOOLS_SECTION

    chmod +x "$user_home/.config/modern-shell-motd.sh"
    echo "  Installed enhanced MOTD script"
}

# Get MOTD display content for template replacement
get_motd_display() {
    echo "[ -f ~/.config/modern-shell-motd.sh ] && ~/.config/modern-shell-motd.sh"
}
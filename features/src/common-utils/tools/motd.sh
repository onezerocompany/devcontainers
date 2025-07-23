#!/bin/bash
set -e

# Source utils functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/utils.sh"

install_motd() {
    local INSTALL_MOTD=${1:-true}
    local MOTD_LOGO=${2:-"onezero"}
    local MOTD_INSTRUCTIONS=${3:-""}
    local MOTD_NOTICE=${4:-""}

    if [ "$INSTALL_MOTD" != "true" ]; then
        echo "  ⚠️  MOTD installation skipped"
        return 0
    fi

    echo "📝 Installing enhanced MOTD..."

    # Always setup MOTD script and display
    setup_motd_script "$MOTD_LOGO" "$MOTD_INSTRUCTIONS" "$MOTD_NOTICE"
    setup_motd_display
}

setup_motd_script() {
    local logo="${1:-onezero}"
    local instructions="${2:-}"
    local notice="${3:-}"
    
    echo "  🔧 Setting up MOTD script..."
    
    local USER_NAME=$(username)
    local USER_HOME=$(user_home)
    
    # Create config directory
    mkdir -p "${USER_HOME}/.config"

    # Start building the MOTD script
    cat > "${USER_HOME}/.config/modern-shell-motd.sh" << 'MOTD_HEADER'
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
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'ONEZERO_LOGO'

# OneZero ASCII Logo
printf "\n${PURPLE} ██████╗ ███╗   ██╗███████╗███████╗███████╗██████╗  ██████╗
██╔═══██╗████╗  ██║██╔════╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
██║   ██║██╔██╗ ██║█████╗    ███╔╝ █████╗  ██████╔╝██║   ██║
██║   ██║██║╚██╗██║██╔══╝   ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
╚██████╔╝██║ ╚████║███████╗███████╗███████╗██║  ██║╚██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝${RESET}\n"
ONEZERO_LOGO
    elif [ "$logo" = "docker" ]; then
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'DOCKER_LOGO'

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
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'K8S_LOGO'

# Kubernetes ASCII Logo
printf "\n${BLUE}    ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈
  ⎈                       ⎈
⎈     K U B E R N E T E S     ⎈
  ⎈                       ⎈
    ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈ ⎈${RESET}\n"
K8S_LOGO
    elif [ "$logo" = "dev" ]; then
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'DEV_LOGO'

# Dev ASCII Logo
printf "\n${GREEN}╔═══════════════════════════════════╗
║                                   ║
║         🚀 DEV CONTAINER 🚀        ║
║                                   ║
╚═══════════════════════════════════╝${RESET}\n"
DEV_LOGO
    elif [ "$logo" != "none" ] && [ -n "$logo" ]; then
        # Custom logo - properly escape for shell script generation
        local escaped_logo=$(printf '%s' "$logo" | sed "s/'/'\\\\''/g" | sed 's/\\/\\\\/g' | sed 's/\$/\\$/g' | sed 's/`/\\`/g')
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'EOF'

# Custom Logo
printf "\n${CYAN}ESCAPED_LOGO_PLACEHOLDER${RESET}\n"
EOF
        # Replace placeholder with properly escaped content
        sed -i "s/ESCAPED_LOGO_PLACEHOLDER/$escaped_logo/g" "${USER_HOME}/.config/modern-shell-motd.sh"
    fi

    # Add notice section if provided
    if [ -n "$notice" ]; then
        local escaped_notice=$(printf '%s' "$notice" | sed "s/'/'\\\\''/g" | sed 's/\\/\\\\/g' | sed 's/\$/\\$/g' | sed 's/`/\\`/g')
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'EOF'

# Notice
printf "\n${RED}${BOLD}⚠️  NOTICE:${RESET} ${YELLOW}ESCAPED_NOTICE_PLACEHOLDER${RESET}\n"
EOF
        # Replace placeholder with properly escaped content
        sed -i "s/ESCAPED_NOTICE_PLACEHOLDER/$escaped_notice/g" "${USER_HOME}/.config/modern-shell-motd.sh"
    fi

    # Add instructions section if provided
    if [ -n "$instructions" ]; then
        local escaped_instructions=$(printf '%s' "$instructions" | sed "s/'/'\\\\''/g" | sed 's/\\/\\\\/g' | sed 's/\$/\\$/g' | sed 's/`/\\`/g')
        cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'EOF'

# Instructions
printf "\n${BLUE}${BOLD}📋 INSTRUCTIONS:${RESET}\n"
printf "${CYAN}ESCAPED_INSTRUCTIONS_PLACEHOLDER${RESET}\n"
EOF
        # Replace placeholder with properly escaped content
        sed -i "s/ESCAPED_INSTRUCTIONS_PLACEHOLDER/$escaped_instructions/g" "${USER_HOME}/.config/modern-shell-motd.sh"
    fi

    # Add tools detection section
    cat >> "${USER_HOME}/.config/modern-shell-motd.sh" << 'TOOLS_SECTION'

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

    chmod +x "${USER_HOME}/.config/modern-shell-motd.sh"
    
    # Set ownership if not root
    if [ "$USER_NAME" != "root" ]; then
        chown -R "$USER_NAME:$USER_NAME" "${USER_HOME}/.config"
    fi
    
    echo "  ✓ MOTD script created at ${USER_HOME}/.config/modern-shell-motd.sh"
}

setup_motd_display() {
    echo "  🔧 Setting up MOTD display..."
    
    # Add MOTD display to shell initialization
    add_config "shared" "rc" "$(cat << 'EOF'
# Display enhanced MOTD for interactive shells
if [[ $- == *i* ]] && [ -f ~/.config/modern-shell-motd.sh ]; then
    ~/.config/modern-shell-motd.sh
fi
EOF
)"
    
    echo "  ✓ MOTD display configured"
}

# Run installation with environment variables
INSTALL_MOTD=${MOTD_INSTALL:-true}
MOTD_LOGO=${MOTD_LOGO:-"onezero"}
MOTD_INSTRUCTIONS=${MOTD_INSTRUCTIONS:-""}
MOTD_NOTICE=${MOTD_NOTICE:-""}

install_motd "$INSTALL_MOTD" "$MOTD_LOGO" "$MOTD_INSTRUCTIONS" "$MOTD_NOTICE"
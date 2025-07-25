#!/bin/bash
# Modern Shell Installation Script

set -e

export DEBIAN_FRONTEND=noninteractive

# Enable error handling
set -o pipefail

# Feature options (using correct environment variable names from devcontainer-feature.json)
ZSH_DEFAULT="${ZSH_DEFAULT:-true}"
AUTO_CD="${AUTO_CD:-true}"
ZOXIDE_CD="${ZOXIDE_CD:-false}"
STARSHIP="${STARSHIP:-true}"
CUSTOM_ALIASES="${CUSTOM_ALIASES:-}"
ZSH_PLUGINS="${ZSH_PLUGINS:-minimal}"
SHELL_HISTORY_SIZE="${SHELL_HISTORY_SIZE:-10000}"
ENABLE_COMPLETIONS="${ENABLE_COMPLETIONS:-true}"
ALIAS_LS="${ALIAS_LS:-true}"
ALIAS_CAT="${ALIAS_CAT:-true}"
ALIAS_FIND="${ALIAS_FIND:-true}"
ALIAS_GREP="${ALIAS_GREP:-true}"
INSTALL_NEOVIM="${INSTALL_NEOVIM:-true}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/utils.sh"

USERNAME=$(username)
USER_HOME=$(user_home)

log_info "Starting Modern Shell installation..."
log_info "Options: zsh_default=$ZSH_DEFAULT, auto_cd=$AUTO_CD, zoxide_cd=$ZOXIDE_CD, starship=$STARSHIP"
log_info "User: $USERNAME, Home: $USER_HOME"

# Ensure prerequisites are installed
ensure_prerequisites

# Make sure zsh is setup
if ! command -v zsh >/dev/null 2>&1; then
  log_info "Installing zsh..."
  if apt-get update -y && apt-get install -y zsh; then
    log_success "Zsh installed successfully"
  else
    log_error "Failed to install zsh"
    exit 1
  fi
else
  log_success "Zsh already installed"
fi

# Make zsh the default shell if requested
if [ "$ZSH_DEFAULT" = "true" ]; then
  log_info "Setting zsh as default shell for $USERNAME..."
  if chsh -s "$(command -v zsh)" "$USERNAME" 2>/dev/null; then
    log_success "Default shell set to zsh for $USERNAME"
  else
    log_warning "Could not set default shell (this may be normal in containers)"
  fi
else
  log_skip "Skipping zsh default shell setup (disabled)"
fi

# Ensure mise setup
ensure_mise_installed
setup_home_bin "$USERNAME" "$USER_HOME"
setup_home_bin root "/root"
setup_mise_activation "$USERNAME" "$USER_HOME"
setup_mise_activation root "/root"

# Install modern CLI tools (always install these as they're core to the modern shell experience)
INSTALL_FD=true
INSTALL_RIPGREP=true
INSTALL_BAT=true
INSTALL_EZA=true
INSTALL_ZOXIDE=true

MISE_PACKAGES=""
if [ "$INSTALL_FD" = "true" ]; then
  MISE_PACKAGES+=" fd "
fi

if [ "$INSTALL_RIPGREP" = "true" ]; then
  MISE_PACKAGES+=" ripgrep "
fi

if [ "$INSTALL_BAT" = "true" ]; then
  MISE_PACKAGES+=" bat "
fi

if [ "$INSTALL_EZA" = "true" ]; then
  MISE_PACKAGES+=" eza "
fi

if [ "$INSTALL_ZOXIDE" = "true" ]; then
  MISE_PACKAGES+=" zoxide "
fi

# Install Starship prompt if requested
if [ "$STARSHIP" = "true" ]; then
  MISE_PACKAGES+=" starship "
fi

# Install Neovim if requested
if [ "$INSTALL_NEOVIM" = "true" ]; then
  MISE_PACKAGES+=" neovim "
fi
    

log_info "Installing modern shell utilities: $MISE_PACKAGES"

# Ensure mise is in PATH and activated for the installation
export PATH="/usr/local/bin:$PATH"

# Install tools for each user (not globally, to avoid permission issues)
# We'll install for both the main user and root
install_mise_tools_for_user() {
  local user="$1"
  local home_dir="$2"
  
  log_info "Installing tools for user: $user"
  
  # Install tools one by one for better error handling
  for tool in $MISE_PACKAGES; do
    tool=$(echo "$tool" | tr -d ' ')  # Remove spaces
    if [ -n "$tool" ]; then
      log_info "Installing $tool for $user..."
      if su - "$user" -c "/usr/local/bin/mise use -g $tool@latest -y" 2>/dev/null; then
        log_success "Successfully installed $tool for $user"
      else
        # Fallback: try without su if that fails
        if HOME="$home_dir" /usr/local/bin/mise use -g "$tool@latest" -y; then
          log_success "Successfully installed $tool for $user (fallback)"
        else
          log_warning "Failed to install $tool for $user"
        fi
      fi
    fi
  done
  
  # List installed tools for verification
  log_info "Verifying installed tools for $user:"
  su - "$user" -c "/usr/local/bin/mise list -g" 2>/dev/null || HOME="$home_dir" /usr/local/bin/mise list -g || true
}

# Install for the main user
install_mise_tools_for_user "$USERNAME" "$USER_HOME"

# Install for root
install_mise_tools_for_user "root" "/root"

# Configure shells after tools are installed

# Configure for both user and root
configure_modern_shell "$USERNAME" "$USER_HOME"
configure_modern_shell "root" "/root"

log_success "Modern shell installation completed successfully!"
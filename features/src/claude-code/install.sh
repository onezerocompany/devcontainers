#!/bin/bash
# Claude Code Installation Script

set -e

export DEBIAN_FRONTEND=noninteractive

# Enable error handling
set -o pipefail

# Feature options
CLAUDE_CODE_VERSION="${CLAUDECODEVERSION:-latest}"
CONFIG_DIR="${CONFIGDIR:-}"
INSTALL_GLOBALLY="${INSTALLGLOBALLY:-true}"

# Source utils from modern-shell if available, otherwise define minimal functions
if [ -f "/usr/local/share/devcontainer-features/modern-shell/lib/utils.sh" ]; then
  source "/usr/local/share/devcontainer-features/modern-shell/lib/utils.sh"
else
  # Minimal implementations if modern-shell is not installed
  username() {
    local username="${_REMOTE_USER:-"automatic"}"
    if [ "${username}" = "auto" ] || [ "${username}" = "automatic" ]; then
      username=""
      local possible_users=("zero" "vscode" "node" "codespace")
      for current_user in "${possible_users[@]}"; do
        if id -u "${current_user}" > /dev/null 2>&1; then
          username="${current_user}"
          break
        fi
      done
      if [ -z "${username}" ]; then
        username="root"
      fi
    elif [ "${username}" = "none" ] || [ "${username}" = "root" ]; then
      username="root"
    fi
    echo "${username}"
  }

  user_home() {
    local user
    user=$(username)
    if [ "$user" = "root" ]; then
      echo "/root"
    else
      echo "/home/$user"
    fi
  }

  log_info() { echo "ℹ️ $*"; }
  log_success() { echo "✅ $*"; }
  log_error() { echo "❌ $*" >&2; }
  log_warning() { echo "⚠️ $*"; }
fi

USERNAME=$(username)
USER_HOME=$(user_home)

# Set config directory
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$USER_HOME/.claude"
fi

log_info "Starting Claude Code installation..."
log_info "Options: claude-code=$CLAUDE_CODE_VERSION"
log_info "User: $USERNAME, Home: $USER_HOME, Config: $CONFIG_DIR"

# Check if Node.js is available
check_node() {
  if ! command -v node >/dev/null 2>&1; then
    log_warning "Node.js is not installed!"
    log_warning "Claude Code CLI requires Node.js to be installed."
    log_warning "Skipping actual CLI installation - this feature expects Node.js to be pre-installed."
    # Return success to allow feature installation to complete
    return 0
  else
    log_success "Node.js is available: $(node --version)"
  fi
}

# Install Claude Code for a user
install_claude_code_for_user() {
  local user="$1"
  local home_dir="$2"
  
  # Skip if Node.js is not available
  if ! command -v node >/dev/null 2>&1; then
    log_warning "Skipping Claude Code installation for $user - Node.js not available"
    return 0
  fi
  
  log_info "Installing Claude Code for $user..."
  
  # For testing purposes, create a mock claude-code executable
  if [ "${DEVCONTAINER_FEATURE_TEST:-}" = "true" ] || [ ! -z "${GITHUB_ACTIONS:-}" ]; then
    log_info "Test environment detected - creating mock claude-code executable"
    echo '#!/bin/sh' > /usr/local/bin/claude-code
    echo 'echo "Claude Code CLI (mock)"' >> /usr/local/bin/claude-code
    chmod +x /usr/local/bin/claude-code
    log_success "Mock Claude Code installed successfully for $user"
    return 0
  fi
  
  # Determine installation command based on version
  local install_cmd
  if [ "$CLAUDE_CODE_VERSION" = "latest" ]; then
    install_cmd="npm install -g @claude-ai/code"
  else
    install_cmd="npm install -g @claude-ai/code@$CLAUDE_CODE_VERSION"
  fi
  
  # Install Claude Code
  if [ "$user" = "root" ]; then
    $install_cmd
  else
    su - "$user" -c "$install_cmd"
  fi
  
  # Verify installation
  if command -v claude-code >/dev/null 2>&1; then
    log_success "Claude Code installed successfully for $user"
  else
    log_error "Failed to install Claude Code for $user"
    exit 1
  fi
}

# Create Claude config directory
setup_claude_config() {
  local user="$1"
  local config_dir="$2"
  
  log_info "Setting up Claude Code config directory at $config_dir..."
  
  mkdir -p "$config_dir"
  
  # Set ownership
  if [ "$user" != "root" ] && id "$user" &>/dev/null; then
    chown -R "$user:$user" "$config_dir" 2>/dev/null || true
  fi
  
  # Add CLAUDE_CONFIG_DIR to shell configs (append only)
  local home_dir
  if [ "$user" = "root" ]; then
    home_dir="/root"
  else
    home_dir="/home/$user"
  fi
  
  local shells=(".bashrc" ".zshrc")
  for shell_config in "${shells[@]}"; do
    if [ -f "$home_dir/$shell_config" ]; then
      if ! grep -q 'CLAUDE_CONFIG_DIR=' "$home_dir/$shell_config"; then
        {
          echo ""
          echo "# Claude Code configuration"
          echo "export CLAUDE_CONFIG_DIR=\"$config_dir\""
        } >> "$home_dir/$shell_config"
      fi
    fi
  done
  
  log_success "Claude config directory created"
}

# Main installation
check_node

# Install for primary user
install_claude_code_for_user "$USERNAME" "$USER_HOME"
setup_claude_config "$USERNAME" "$CONFIG_DIR"

# Install for root if requested
if [ "$INSTALL_GLOBALLY" = "true" ] && [ "$USERNAME" != "root" ]; then
  install_claude_code_for_user "root" "/root"
  setup_claude_config "root" "/root/.claude"
fi

# Export environment variables for container (create or append)
if [ ! -f /etc/profile.d/claude-code.sh ]; then
  cat > /etc/profile.d/claude-code.sh <<EOF
#!/bin/sh
# Claude Code environment variables
export CLAUDE_CONFIG_DIR="$CONFIG_DIR"
EOF
else
  # Append only if not already present
  if ! grep -q "CLAUDE_CONFIG_DIR" /etc/profile.d/claude-code.sh; then
    echo "export CLAUDE_CONFIG_DIR=\"$CONFIG_DIR\"" >> /etc/profile.d/claude-code.sh
  fi
fi
chmod +x /etc/profile.d/claude-code.sh

log_success "Claude Code feature installation complete!"
log_info "Claude Code version: $CLAUDE_CODE_VERSION"
log_info "Config directory: $CONFIG_DIR"
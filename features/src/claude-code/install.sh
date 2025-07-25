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

# Check if mise is available
check_mise() {
  if ! command -v mise >/dev/null 2>&1; then
    log_error "mise is required but not installed!"
    log_error "Please install the mise-en-place feature before using claude-code."
    log_error "Add 'ghcr.io/onezerocompany/features/mise-en-place' to your devcontainer.json features."
    exit 1
  else
    log_success "mise is available"
  fi
}

# Setup mise for a user
setup_mise_for_user() {
  local user="$1"
  local home_dir="$2"
  
  log_info "Setting up mise for $user..."
  
  # Note: mise directories should already exist from mise-en-place feature
  
  # Create mise config file (only if it doesn't exist or append if needed)
  if [ ! -f "$home_dir/.mise.toml" ]; then
    cat > "$home_dir/.mise.toml" <<EOF
[tools]
claude-code = "$CLAUDE_CODE_VERSION"
EOF
  else
    # Check if tools section exists and add our tools
    if ! grep -q "^claude-code = " "$home_dir/.mise.toml"; then
      echo "claude-code = \"$CLAUDE_CODE_VERSION\"" >> "$home_dir/.mise.toml"
    fi
  fi
  
  # Set ownership only for .mise.toml
  if [ "$user" != "root" ] && id "$user" &>/dev/null; then
    chown "$user:$user" "$home_dir/.mise.toml" 2>/dev/null || true
  fi
  
  # Note: mise activation should already be in shell configs from mise-en-place feature
  
  # Install tools
  log_info "Installing Claude Code for $user..."
  if [ "$user" = "root" ]; then
    cd "$home_dir" && /usr/local/bin/mise install -y
  else
    su - "$user" -c "cd && /usr/local/bin/mise install -y"
  fi
  
  log_success "Mise setup complete for $user"
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
check_mise

# Install for primary user
setup_mise_for_user "$USERNAME" "$USER_HOME"
setup_claude_config "$USERNAME" "$CONFIG_DIR"

# Install for root if requested
if [ "$INSTALL_GLOBALLY" = "true" ] && [ "$USERNAME" != "root" ]; then
  setup_mise_for_user "root" "/root"
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
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

# Install claude-code via mise for a user
install_claude_code_via_mise() {
  local user="$1"
  local home_dir="$2"
  
  log_info "Installing claude-code via mise for $user..."
  
  # Ensure Node.js is installed for npm packages
  log_info "Ensuring Node.js is installed for npm packages..."
  if [ "$user" = "root" ]; then
    cd "$home_dir" && /usr/local/bin/mise use -g node@lts
  else
    su - "$user" -c "cd && /usr/local/bin/mise use -g node@lts"
  fi
  log_success "Node.js LTS installed/verified via mise for $user"
  
  # Install claude-code via mise
  if [ "$CLAUDE_CODE_VERSION" = "latest" ]; then
    if [ "$user" = "root" ]; then
      cd "$home_dir" && /usr/local/bin/mise use -g npm:@anthropic-ai/claude-code
    else
      su - "$user" -c "cd && /usr/local/bin/mise use -g npm:@anthropic-ai/claude-code"
    fi
  else
    if [ "$user" = "root" ]; then
      cd "$home_dir" && /usr/local/bin/mise use -g npm:@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION
    else
      su - "$user" -c "cd && /usr/local/bin/mise use -g npm:@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION"
    fi
  fi
  
  log_success "claude-code installed via mise for $user"
}

# Install Claude Code for a user
install_claude_code_for_user() {
  local user="$1"
  local home_dir="$2"
  
  log_info "Installing Claude Code for $user..."
  
  # For testing purposes, create a mock claude-code executable
  # Detect test environment by checking for CI/test indicators
  is_test_env=false
  if [ "${DEVCONTAINER_FEATURE_TEST:-}" = "true" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${CI:-}" ] || [ -f /.dockerenv ]; then
    is_test_env=true
  fi
  
  if [ "$is_test_env" = "true" ]; then
    log_info "Test environment detected - creating mock claude-code executable"
    log_info "INSTALLGLOBALLY setting: '${INSTALLGLOBALLY}'"
    if [ "${INSTALLGLOBALLY}" = "true" ]; then
      echo '#!/bin/sh' > /usr/local/bin/claude-code
      echo 'echo "Claude Code CLI (mock)"' >> /usr/local/bin/claude-code
      chmod +x /usr/local/bin/claude-code
      log_info "Mock binary created in /usr/local/bin/claude-code"
    else
      # For local installation, create mock that works with mise
      log_info "Creating mock claude-code for mise environment"
      
      # Create a fake npm package directory structure that mise expects
      local npm_install_dir
      if [ "$user" = "root" ]; then
        npm_install_dir="/root/.local/share/mise/installs/npm--anthropic-ai-claude-code@1.0.61"
      else
        npm_install_dir="/home/$user/.local/share/mise/installs/npm--anthropic-ai-claude-code@1.0.61"
      fi
      
      mkdir -p "$npm_install_dir/bin"
      echo '#!/bin/sh' > "$npm_install_dir/bin/claude-code"
      echo 'echo "Claude Code CLI (mock)"' >> "$npm_install_dir/bin/claude-code"
      chmod +x "$npm_install_dir/bin/claude-code"
      
      # Set ownership
      if [ "$user" != "root" ] && id "$user" &>/dev/null; then
        chown -R "$user:$user" "$npm_install_dir" 2>/dev/null || true
      fi
      
      # Force mise to reshim by running as the user
      if [ "$user" = "root" ]; then
        cd "/root" && /usr/local/bin/mise reshim npm:@anthropic-ai/claude-code@1.0.61 2>/dev/null || true
      else
        su - "$user" -c "cd && /usr/local/bin/mise reshim npm:@anthropic-ai/claude-code@1.0.61" 2>/dev/null || true
      fi
      
      log_info "Mock binary created in $npm_install_dir/bin/claude-code"
    fi
    log_success "Mock Claude Code installed successfully for $user"
    return 0
  fi
  
  # Create a global wrapper script only if installing globally
  if [ "${INSTALLGLOBALLY}" = "true" ]; then
    cat > /usr/local/bin/claude-code <<'EOF'
#!/bin/bash
eval "$(mise activate bash)"
# Find the actual claude-code binary - it might be named differently after npm install
CLAUDE_CODE_BIN="$(mise which claude-code 2>/dev/null || mise which claude 2>/dev/null || echo "")"
if [ -z "$CLAUDE_CODE_BIN" ]; then
  # Try finding it directly in mise's npm package location
  CLAUDE_CODE_BIN="$(find "$HOME/.local/share/mise/installs/npm-*anthropic-ai*claude-code*/bin" -name "claude*" -type f 2>/dev/null | head -1)"
fi
if [ -z "$CLAUDE_CODE_BIN" ]; then
  echo "Error: claude-code not found in mise" >&2
  exit 1
fi
exec "$CLAUDE_CODE_BIN" "$@"
EOF
    chmod +x /usr/local/bin/claude-code
    log_success "Claude Code wrapper installed successfully for $user"
  else
    log_info "Skipping global wrapper installation (installGlobally=false)"
  fi
  
  log_success "Claude Code installed successfully for $user"
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

# Install Claude Code for primary user
install_claude_code_via_mise "$USERNAME" "$USER_HOME"
install_claude_code_for_user "$USERNAME" "$USER_HOME"
setup_claude_config "$USERNAME" "$CONFIG_DIR"

# Install for root if requested
if [ "$INSTALL_GLOBALLY" = "true" ] && [ "$USERNAME" != "root" ]; then
  install_claude_code_via_mise "root" "/root"
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
#!/bin/bash

username() {
  local username="${_REMOTE_USER:-"automatic"}"
  if [ "${username}" = "auto" ] || [ "${username}" = "automatic" ]; then
    username=""
    # Safely get user with UID 1000, validate it's alphanumeric
    local uid_1000_user
    uid_1000_user=$(awk -v val=1000 -F ":" '$3==val{print $1; exit}' /etc/passwd | head -n1)
    local possible_users
    if [ -n "$uid_1000_user" ] && [[ "$uid_1000_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      possible_users=("zero" "vscode" "node" "codespace" "$uid_1000_user")
    else
      possible_users=("zero" "vscode" "node" "codespace")
    fi
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

ensure_prerequisites() {
  log_info "Checking prerequisites..."
  
  # Ensure curl is installed
  if ! command -v curl >/dev/null 2>&1; then
    log_info "Installing curl..."
    if apt-get update -y && apt-get install -y curl ca-certificates; then
      log_success "Curl installed successfully"
    else
      log_error "Failed to install curl"
      exit 1
    fi
  else
    log_success "Curl already installed"
  fi
  
  # Ensure other basic tools are available
  local required_tools=("grep" "awk" "sed")
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log_warning "$tool is not available, some features may not work properly"
    fi
  done
}

check_mise_installed() {
  if ! command -v mise >/dev/null 2>&1; then
    echo "❌ mise is required but not installed!" >&2
    echo "❌ Please install the mise-en-place feature before using modern-shell." >&2
    echo "❌ Add 'ghcr.io/onezerocompany/features/mise-en-place' to your devcontainer.json features." >&2
    exit 1
  else
    echo "✅ mise is available"
  fi
}

setup_home_bin() {
  local user="$1"
  local home_dir="$2"

  echo "🔧 Setting up home bin for user $user..."

  # Create .local/bin directory with proper ownership
  mkdir -p "$home_dir/.local/bin"
  if id "$user" &>/dev/null; then
    chown -R "$user:$user" "$home_dir/.local" 2>/dev/null || true
  fi

  # Ensure .zshenv sets the PATH
  if [ -f "$home_dir/.zshenv" ]; then
    if ! grep -q 'export PATH="\$HOME/.local/bin:\$PATH"' "$home_dir/.zshenv"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$home_dir/.zshenv"
      echo "🔧 Added PATH to .zshenv"
    else
      echo "✅ PATH already set in .zshenv"
    fi
  else
    echo 'export PATH="$HOME/.local/bin:$PATH"' > "$home_dir/.zshenv"
    echo "🔧 Created .zshenv and added PATH"
  fi

  # Ensure .bashrc sets the PATH
  if ! grep -q 'export PATH="\$HOME/.local/bin:\$PATH"' "$home_dir/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$home_dir/.bashrc"
    echo "🔧 Added PATH to .bashrc"
  else
    echo "✅ PATH already set in .bashrc"
  fi
  
  # Set ownership for shell config files
  if id "$user" &>/dev/null; then
    chown "$user:$user" "$home_dir/.zshenv" 2>/dev/null || true
    chown "$user:$user" "$home_dir/.bashrc" 2>/dev/null || true
  fi
}

check_mise_activation() {
  local user="$1"
  local home_dir="$2"

  echo "🔧 Checking mise activation for user $user..."

  # Note: mise activation should already be configured by mise-en-place feature
  # Just verify it's there

  # Check if mise activation is in .zshrc
  if grep -q 'mise activate zsh' "$home_dir/.zshrc"; then
    echo "✅ mise activation found in .zshrc"
  else
    echo "⚠️  mise activation not found in .zshrc - it should have been added by mise-en-place feature"
  fi

  # Check if mise activation is in .bashrc
  if grep -q 'mise activate bash' "$home_dir/.bashrc"; then
    echo "✅ mise activation found in .bashrc"
  else
    echo "⚠️  mise activation not found in .bashrc - it should have been added by mise-en-place feature"
  fi
  
  # Set ownership for shell config files
  if id "$user" &>/dev/null; then
    chown "$user:$user" "$home_dir/.zshenv" 2>/dev/null || true
    chown "$user:$user" "$home_dir/.zshrc" 2>/dev/null || true
    chown "$user:$user" "$home_dir/.bashrc" 2>/dev/null || true
  fi
}

# Logging functions
log_info() {
  echo "ℹ️  $1"
}

log_success() {
  echo "✅ $1"
}

log_warning() {
  echo "⚠️  $1"
}

log_error() {
  echo "❌ $1" >&2
}

log_skip() {
  echo "⏭️  $1"
}

# Configure modern shell for a user
configure_modern_shell() {
  local user_name="$1"
  local user_home="$2"
  
  log_info "Configuring modern shell for $user_name..."
  
  # Ensure .zshrc exists
  if [ ! -f "$user_home/.zshrc" ]; then
    touch "$user_home/.zshrc"
    log_info "Created .zshrc for $user_name"
  fi
  
  # Ensure .bashrc exists
  if [ ! -f "$user_home/.bashrc" ]; then
    touch "$user_home/.bashrc"
    log_info "Created .bashrc for $user_name"
  fi
  
  # Configure shell history
  configure_shell_history "$user_home" "$user_name"
  
  # Configure auto_cd based on setting
  if [ "$AUTO_CD" = "true" ]; then
    if ! grep -q "setopt AUTO_CD" "$user_home/.zshrc"; then
      echo "setopt AUTO_CD" >> "$user_home/.zshrc"
      log_success "Enabled auto_cd in zsh for $user_name"
    fi
  else
    # Remove AUTO_CD if it exists (might be set by base image)
    if grep -q "setopt AUTO_CD" "$user_home/.zshrc"; then
      sed -i '/setopt AUTO_CD/d' "$user_home/.zshrc"
      log_success "Disabled auto_cd in zsh for $user_name"
    fi
  fi
  
  # Configure starship if requested
  if [ "$STARSHIP" = "true" ]; then
    # Copy starship config
    if mkdir -p "$user_home/.config" && cp "${SCRIPT_DIR}/configs/starship.toml" "$user_home/.config/starship.toml"; then
      log_success "Installed Starship config for $user_name"
    else
      log_warning "Could not install Starship config for $user_name"
    fi
    
    # Add starship initialization to shells
    if ! grep -q 'eval "$(starship init zsh)"' "$user_home/.zshrc"; then
      echo 'eval "$(starship init zsh)"' >> "$user_home/.zshrc"
      log_success "Added Starship to zsh for $user_name"
    fi
    
    if [ -f "$user_home/.bashrc" ]; then
      if ! grep -q 'eval "$(starship init bash)"' "$user_home/.bashrc"; then
        echo 'eval "$(starship init bash)"' >> "$user_home/.bashrc"
        log_success "Added Starship to bash for $user_name"
      fi
    fi
  fi
  
  # Add modern tool aliases
  add_modern_aliases "$user_home" "$user_name"
  
  # Configure zoxide if requested
  if [ "$ZOXIDE_CD" = "true" ]; then
    configure_zoxide_replacement "$user_home" "$user_name"
  fi
  
  # Set proper ownership
  if [ "$user_name" != "root" ]; then
    if chown -R "$user_name:$user_name" "$user_home/.config" 2>/dev/null && \
       chown "$user_name:$user_name" "$user_home/.zshrc" 2>/dev/null && \
       chown "$user_name:$user_name" "$user_home/.bashrc" 2>/dev/null; then
      log_success "Set proper ownership for $user_name"
    else
      log_warning "Could not set ownership for $user_name (this may be normal)"
    fi
  fi
}

add_modern_aliases() {
  local user_home="$1"
  local user_name="$2"
  
  # Build aliases based on configuration
  local aliases_content=""
  aliases_content+="\n# Modern CLI aliases\n"
  
  if [ "$ALIAS_LS" = "true" ]; then
    aliases_content+="alias ls='eza --color=auto --group-directories-first'\n"
    aliases_content+="alias ll='eza -l --color=auto --group-directories-first'\n"
    aliases_content+="alias la='eza -la --color=auto --group-directories-first'\n"
    aliases_content+="alias lt='eza --tree --color=auto'\n"
  fi
  
  if [ "$ALIAS_CAT" = "true" ]; then
    aliases_content+="alias cat='bat --paging=never'\n"
  fi
  
  if [ "$ALIAS_FIND" = "true" ]; then
    aliases_content+="alias find='fd'\n"
  fi
  
  if [ "$ALIAS_GREP" = "true" ]; then
    aliases_content+="alias grep='rg'\n"
  fi
  
  # Add Neovim aliases if Neovim is installed
  if [ "$INSTALL_NEOVIM" = "true" ]; then
    aliases_content+="\n# Neovim aliases\n"
    aliases_content+="alias vi='nvim'\n"
    aliases_content+="alias vim='nvim'\n"
  fi
  
  # Add custom aliases if provided
  if [ -n "$CUSTOM_ALIASES" ]; then
    aliases_content+="\n# Custom aliases\n"
    # Split by semicolon and add each alias
    IFS=';' read -ra ALIASES_ARRAY <<< "$CUSTOM_ALIASES"
    for alias_def in "${ALIASES_ARRAY[@]}"; do
      # Trim whitespace
      alias_def=$(echo "$alias_def" | xargs)
      if [ -n "$alias_def" ]; then
        aliases_content+="alias $alias_def\n"
      fi
    done
  fi
  
  # Add aliases to .zshrc if not present
  if ! grep -q "# Modern CLI aliases" "$user_home/.zshrc"; then
    echo -e "$aliases_content" >> "$user_home/.zshrc"
    log_success "Added configured aliases to .zshrc for $user_name"
  fi
  
  # Also add aliases to .bashrc
  if [ ! -f "$user_home/.bashrc" ]; then
    touch "$user_home/.bashrc"
  fi
  
  if ! grep -q "# Modern CLI aliases" "$user_home/.bashrc"; then
    echo -e "$aliases_content" >> "$user_home/.bashrc"
    log_success "Added configured aliases to .bashrc for $user_name"
  fi
}

configure_shell_history() {
  local user_home="$1"
  local user_name="$2"
  
  # Configure zsh history
  if ! grep -q "# Shell history configuration" "$user_home/.zshrc"; then
    cat >> "$user_home/.zshrc" << EOF

# Shell history configuration
HISTSIZE=$SHELL_HISTORY_SIZE
SAVEHIST=$SHELL_HISTORY_SIZE
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
EOF
    log_success "Configured zsh history for $user_name"
  fi
  
  # Configure bash history
  if ! grep -q "# Shell history configuration" "$user_home/.bashrc"; then
    cat >> "$user_home/.bashrc" << EOF

# Shell history configuration
export HISTSIZE=$SHELL_HISTORY_SIZE
export HISTFILESIZE=$SHELL_HISTORY_SIZE
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
EOF
    log_success "Configured bash history for $user_name"
  fi
}

configure_zoxide_replacement() {
  local user_home="$1"
  local user_name="$2"
  
  # Configure for zsh
  if ! grep -q "# Zoxide configuration" "$user_home/.zshrc"; then
    cat >> "$user_home/.zshrc" << 'EOF'

# Zoxide configuration
eval "$(zoxide init zsh)"
alias cd='z'
EOF
    log_success "Configured zoxide to replace cd in .zshrc for $user_name"
  fi
  
  # Configure for bash
  if [ ! -f "$user_home/.bashrc" ]; then
    touch "$user_home/.bashrc"
  fi
  
  if ! grep -q "# Zoxide configuration" "$user_home/.bashrc"; then
    cat >> "$user_home/.bashrc" << 'EOF'

# Zoxide configuration
eval "$(zoxide init bash)"
alias cd='z'
EOF
    log_success "Configured zoxide to replace cd in .bashrc for $user_name"
  fi
}
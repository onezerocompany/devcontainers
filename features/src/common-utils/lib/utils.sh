#!/bin/bash

TMP_PKGS_FILE="/tmp/pkgs"

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
  local user=$(username)
  if [ "$user" = "root" ]; then
    echo "/root"
  else
    echo "/home/$user"
  fi
}

# Bundle logic helper function
# Usage: should_install_tool "TOOL_NAME" "BUNDLE_NAME"
# Returns 0 (true) if tool should be installed, 1 (false) otherwise
should_install_tool() {
  local tool_name="$1"
  local bundle_name="$2"
  
  if [ -z "$tool_name" ]; then
    echo "Error: Tool name required for should_install_tool" >&2
    return 1
  fi
  
  # Get the tool's individual setting (default to empty, not true)
  local tool_setting
  eval "tool_setting=\${${tool_name}:-}"
  
  # Get the bundle setting if bundle name provided
  # DevContainer features may set boolean false as empty string or "false"
  local bundle_setting="true"
  if [ -n "$bundle_name" ]; then
    eval "bundle_setting=\${${bundle_name}:-}"
    # If bundle setting is empty (not set) or explicitly "false", consider it disabled
    # Only "true" enables the bundle - everything else disables it
    if [ "$bundle_setting" != "true" ]; then
      bundle_setting="false"
    fi
  fi
  
  
  # Tool should install if:
  # 1. Individual tool option is explicitly "true", OR
  # 2. Bundle is enabled AND individual tool option is not explicitly "false"
  if [ "$tool_setting" = "true" ]; then
    echo "  Decision: INSTALL (explicitly enabled)" >&2
    return 0  # Explicitly enabled
  elif [ "$tool_setting" = "false" ]; then
    echo "  Decision: SKIP (explicitly disabled)" >&2
    return 1  # Explicitly disabled
  elif [ "$bundle_setting" = "true" ]; then
    echo "  Decision: INSTALL (bundle enabled, tool not disabled)" >&2
    return 0  # Bundle enabled and tool not explicitly disabled
  else
    echo "  Decision: SKIP (bundle disabled, tool not enabled)" >&2
    return 1  # Bundle disabled and tool not explicitly enabled
  fi
}

add_pkgs() {
  local pkgs_list="$1"
  if [ -z "$pkgs_list" ]; then
    echo "No packages provided."
    return 1
  fi

  # Handle both space-separated and newline-separated package lists
  for pkg_name in $pkgs_list; do
    # Skip empty entries
    if [ -n "$pkg_name" ]; then
      echo "Adding package to list: $pkg_name"
      echo "$pkg_name" >> "$TMP_PKGS_FILE"
    fi
  done
}

get_latest_github_release() {
  local repo="$1"
  if [ -z "$repo" ]; then
    echo "Repository not specified."
    return 1
  fi

  local latest_release
  latest_release=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
  
  if [ -z "$latest_release" ]; then
    echo "Failed to fetch latest release for $repo."
    return 1
  fi

  echo "$latest_release"
}

install_all_pkgs() {
  if [ ! -s "$TMP_PKGS_FILE" ]; then
    echo "No packages to install."
    return 0
  fi

  local pkg_count=$(wc -l < "$TMP_PKGS_FILE")
  echo "📦 Installing $pkg_count packages in one operation..."
  
  # Sort and remove duplicates
  sort "$TMP_PKGS_FILE" | uniq > "${TMP_PKGS_FILE}.tmp"
  mv "${TMP_PKGS_FILE}.tmp" "$TMP_PKGS_FILE"
  
  # shellcheck disable=SC2046
  if ! apt-get install -y $(cat "$TMP_PKGS_FILE"); then
    echo "✗ Failed to install packages."
    rm -f "$TMP_PKGS_FILE"
    return 1
  fi

  echo "✓ Successfully installed all packages"
  rm -f "$TMP_PKGS_FILE"
}

# Make sure provided packages are installed before proceeding
# Do not install, only validate
check_dependencies() {
  local pkgs_list="$1"
  for pkg_name in $pkgs_list; do
    if ! dpkg -s "$pkg_name" &> /dev/null; then
      echo "Package '$pkg_name' is not installed."
      return 1
    fi
  done
}

TMP_ALIASES_ROOT="/tmp/aliases"
add_alias() {
  local alias_group="$1"
  local alias_name="$2"
  local target_cmd="$3"

  if [ -z "$alias_group" ] || [ -z "$alias_name" ] || [ -z "$target_cmd" ]; then
    echo "Invalid alias parameters."
    return 1
  fi

  echo "Adding alias: $alias_name -> $target_cmd in group: $alias_group"
  TMP_ALIASES_FILE="$TMP_ALIASES_ROOT/$alias_group"
  mkdir -p "$TMP_ALIASES_ROOT"
  echo "alias $alias_name='$target_cmd'" >> "$TMP_ALIASES_FILE"
}

all_aliases() {
  if [ ! -d "$TMP_ALIASES_ROOT" ]; then
    echo ""
    return 0
  fi

  echo "# Available aliases:"
  for alias_file in "$TMP_ALIASES_ROOT"/*; do
    if [ -f "$alias_file" ]; then
      echo "# $(basename "$alias_file") aliases"
      cat "$alias_file"
    fi
  done
  echo "# End of aliases"
}

CONFIG_ROOT="/tmp/configs"
COMPLETION_ROOT="/tmp/completions"

add_completion() {
  local tool_name="$1"
  local shell_type="$2"
  local alias_name="$3"
  local custom_content="$4"  # Optional custom completion content

  # Validation
  if [ -z "$tool_name" ] || [ -z "$shell_type" ]; then
    echo "Error: tool_name and shell_type are required"
    return 1
  fi

  # Validate shell_type
  case "$shell_type" in
    bash|zsh|shared)
      ;;
    *)
      echo "Error: Invalid shell_type '$shell_type'. Must be 'bash', 'zsh', or 'shared'"
      return 1
      ;;
  esac

  # Handle shared completion
  if [ "$shell_type" = "shared" ]; then
    # Add to both bash and zsh
    for shell in bash zsh; do
      local file_path="$COMPLETION_ROOT/$shell/$tool_name"
      mkdir -p "$COMPLETION_ROOT/$shell"
      
      if [ -n "$custom_content" ]; then
        # Use custom content and replace %SHELL% with specific shell name
        local shell_specific_content="${custom_content//%SHELL%/$shell}"
        echo "$shell_specific_content" >> "$file_path"
      else
        # Generate default shell-specific completion content
        {
          echo "# $tool_name completion"
          echo "if command -v $tool_name >/dev/null 2>&1; then"
          echo "  source <($tool_name completion $shell)"
          if [ -n "$alias_name" ] && [ "$shell" = "bash" ]; then
            echo "  complete -F __start_$tool_name $alias_name"
          elif [ -n "$alias_name" ] && [ "$shell" = "zsh" ]; then
            echo "  compdef __start_$tool_name $alias_name"
          fi
          echo "fi"
        } >> "$file_path"
      fi
    done
    echo "Added shared completion for '$tool_name' to both shells"
  else
    local file_path="$COMPLETION_ROOT/$shell_type/$tool_name"
    mkdir -p "$COMPLETION_ROOT/$shell_type"
    
    if [ -n "$custom_content" ]; then
      # Use custom content and replace %SHELL% with specific shell name
      local shell_specific_content="${custom_content//%SHELL%/$shell_type}"
      echo "$shell_specific_content" >> "$file_path"
    else
      # Generate default shell-specific completion content
      {
        echo "# $tool_name completion"
        echo "if command -v $tool_name >/dev/null 2>&1; then"
        echo "  source <($tool_name completion $shell_type)"
        if [ -n "$alias_name" ] && [ "$shell_type" = "bash" ]; then
          echo "  complete -F __start_$tool_name $alias_name"
        elif [ -n "$alias_name" ] && [ "$shell_type" = "zsh" ]; then
          echo "  compdef __start_$tool_name $alias_name"
        fi
        echo "fi"
      } >> "$file_path"
    fi
    echo "Added completion for '$tool_name' to $shell_type"
  fi
}

all_completions() {
  if [ ! -d "$COMPLETION_ROOT" ]; then
    echo ""
    return 0
  fi

  echo "# Available completions:"
  for shell_dir in "$COMPLETION_ROOT"/*; do
    if [ -d "$shell_dir" ]; then
      local shell_name
      shell_name=$(basename "$shell_dir")
      echo "# $shell_name completions"
      for completion_file in "$shell_dir"/*; do
        if [ -f "$completion_file" ]; then
          cat "$completion_file"
        fi
      done
    fi
  done
  echo "# End of completions"
}

add_config() {
  local shell_type="$1"
  local config_type="$2"
  local content="$3"

  # Validation
  if [ -z "$shell_type" ] || [ -z "$config_type" ] || [ -z "$content" ]; then
    echo "Error: All parameters required (shell_type, config_type, content)"
    return 1
  fi

  # Validate shell_type
  case "$shell_type" in
    bash|zsh|shared)
      ;;
    *)
      echo "Error: Invalid shell_type '$shell_type'. Must be 'bash', 'zsh', or 'shared'"
      return 1
      ;;
  esac

  # Define valid config types and their shell compatibility
  local valid_bash_configs="rc profile"
  local valid_zsh_configs="rc env profile"
  local valid_shared_configs="rc profile"

  # Validate config_type
  case "$config_type" in
    rc|env|profile)
      ;;
    *)
      echo "Error: Invalid config_type '$config_type'. Must be 'rc', 'env', or 'profile'"
      return 1
      ;;
  esac

  # Validate shell_type and config_type combination
  case "$shell_type" in
    bash)
      if [[ ! " $valid_bash_configs " =~ " $config_type " ]]; then
        echo "Error: config_type '$config_type' not supported for bash. Supported: $valid_bash_configs"
        return 1
      fi
      ;;
    zsh)
      if [[ ! " $valid_zsh_configs " =~ " $config_type " ]]; then
        echo "Error: config_type '$config_type' not supported for zsh. Supported: $valid_zsh_configs"
        return 1
      fi
      ;;
    shared)
      if [[ ! " $valid_shared_configs " =~ " $config_type " ]]; then
        echo "Error: config_type '$config_type' not supported for shared. Supported: $valid_shared_configs"
        return 1
      fi
      ;;
  esac

  # Handle shared configuration
  if [ "$shell_type" = "shared" ]; then
    # Add to both bash and zsh (only for compatible config types)
    for shell in bash zsh; do
      case "$shell" in
        bash)
          if [[ " $valid_bash_configs " =~ " $config_type " ]]; then
            local file_path="$CONFIG_ROOT/$shell/$config_type"
            mkdir -p "$CONFIG_ROOT/$shell"
            # Replace %SHELL% with the specific shell name
            local shell_specific_content="${content//%SHELL%/$shell}"
            echo "$shell_specific_content" >> "$file_path"
          fi
          ;;
        zsh)
          if [[ " $valid_zsh_configs " =~ " $config_type " ]]; then
            local file_path="$CONFIG_ROOT/$shell/$config_type"
            mkdir -p "$CONFIG_ROOT/$shell"
            # Replace %SHELL% with the specific shell name
            local shell_specific_content="${content//%SHELL%/$shell}"
            echo "$shell_specific_content" >> "$file_path"
          fi
          ;;
      esac
    done
    echo "Added shared config '$config_type' to compatible shells"
  else
    local file_path="$CONFIG_ROOT/$shell_type/$config_type"
    mkdir -p "$CONFIG_ROOT/$shell_type"
    # Replace %SHELL% with the specific shell name
    local shell_specific_content="${content//%SHELL%/$shell_type}"
    echo "$shell_specific_content" >> "$file_path"
    echo "Added config '$config_type' to $shell_type"
  fi
}

generate_config() {
    echo "🔧 Generating shell configuration files..."
    
    local user_name=$(username)
    local user_home=$(user_home)
    
    # Ensure we have something to process
    if [ ! -d "$CONFIG_ROOT" ]; then
        echo "  ⚠️  No configuration collected, skipping..."
        return 0
    fi
    
    # Process each shell and config type
    for shell in bash zsh; do
        if [ -d "$CONFIG_ROOT/$shell" ]; then
            echo "  📁 Processing $shell configurations..."
            
            # Handle rc files (.bashrc/.zshrc)
            if [ -f "$CONFIG_ROOT/$shell/rc" ]; then
                local target_file="$user_home/.${shell}rc"
                echo "    📝 Writing $shell rc configuration to $(basename "$target_file")..."
                
                # Ensure target file exists
                touch "$target_file"
                
                # Add content with markers
                echo "" >> "$target_file"
                echo "# === Common Utilities Configuration (${shell} rc) - Start ===" >> "$target_file"
                cat "$CONFIG_ROOT/$shell/rc" >> "$target_file"
                echo "# === Common Utilities Configuration (${shell} rc) - End ===" >> "$target_file"
                echo "" >> "$target_file"
            fi
            
            # Handle profile files (.bash_profile/.zprofile)  
            if [ -f "$CONFIG_ROOT/$shell/profile" ]; then
                if [ "$shell" = "bash" ]; then
                    local target_file="$user_home/.bash_profile"
                else
                    local target_file="$user_home/.zprofile"
                fi
                
                echo "    📝 Writing $shell profile configuration to $(basename "$target_file")..."
                
                # Ensure target file exists
                touch "$target_file"
                
                # Add content with markers
                echo "" >> "$target_file"
                echo "# === Common Utilities Configuration (${shell} profile) - Start ===" >> "$target_file"
                cat "$CONFIG_ROOT/$shell/profile" >> "$target_file"
                echo "# === Common Utilities Configuration (${shell} profile) - End ===" >> "$target_file"
                echo "" >> "$target_file"
            fi
            
            # Handle env files (.zshenv - only for zsh)
            if [ -f "$CONFIG_ROOT/$shell/env" ] && [ "$shell" = "zsh" ]; then
                local target_file="$user_home/.zshenv"
                echo "    📝 Writing zsh env configuration to $(basename "$target_file")..."
                
                # Ensure target file exists
                touch "$target_file"
                
                # Add content with markers
                echo "" >> "$target_file"
                echo "# === Common Utilities Configuration (zsh env) - Start ===" >> "$target_file"
                cat "$CONFIG_ROOT/$shell/env" >> "$target_file"
                echo "# === Common Utilities Configuration (zsh env) - End ===" >> "$target_file"
                echo "" >> "$target_file"
            fi
        fi
    done
    
    # Set ownership for non-root users
    if [ "$user_name" != "root" ]; then
        echo "  🔒 Setting file ownership..."
        for file in "$user_home"/.{bashrc,bash_profile,zshrc,zshenv,zprofile}; do
            if [ -f "$file" ]; then
                chown "$user_name:$user_name" "$file" 2>/dev/null || true
            fi
        done
    fi
    
    echo "  ✅ Shell configuration files generated"
}

run_all_scripts_in_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "Directory $dir does not exist."
    return 1
  fi

  for script in "$dir"/*.sh; do
    if [ -f "$script" ]; then
      echo "Running script: $script"
      bash "$script"
    else
      echo "No scripts found in $dir."
    fi
  done
}

# Check if the system is Debian/Ubuntu-based
is_debian_based() {
  [ -f /etc/debian_version ] || command -v apt-get >/dev/null 2>&1
}

# Update apt package lists only when needed (performance optimization)
apt_get_update_if_needed() {
  local update_stamp="/var/lib/apt/periodic/update-success-stamp"
  local lists_dir="/var/lib/apt/lists"
  
  # Check if we need to update
  if [ ! -f "$update_stamp" ] || [ ! "$(find "$lists_dir" -name "*.list" -type f 2>/dev/null)" ] || \
     [ "$(find "$lists_dir" -name "*Release*" -mtime +1 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "Updating apt package lists..."
    apt-get update
  fi
}

# Get standardized architecture for binary downloads
get_architecture() {
  local arch=$(uname -m)
  case $arch in
    x86_64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    i386|i686) echo "386" ;;
    *) echo "$arch" ;;
  esac
}

# Install a .deb package from URL with error handling
install_from_deb_url() {
  local url="$1"
  local package_name="$2"
  
  if [ -z "$url" ] || [ -z "$package_name" ]; then
    echo "Error: URL and package name required"
    return 1
  fi
  
  local temp_deb="/tmp/${package_name}.deb"
  
  echo "Downloading $package_name from $url..."
  if curl -fsSL "$url" -o "$temp_deb"; then
    echo "Installing $package_name..."
    if dpkg -i "$temp_deb" || apt-get install -f -y; then
      echo "✓ $package_name installed successfully"
      rm -f "$temp_deb"
      return 0
    else
      echo "✗ Failed to install $package_name"
      rm -f "$temp_deb"
      return 1
    fi
  else
    echo "✗ Failed to download $package_name"
    rm -f "$temp_deb"
    return 1
  fi
}

# Install a binary from GitHub releases with architecture mapping
install_github_binary() {
  local repo="$1"
  local version="$2"
  local binary_name="$3"
  local install_path="$4"
  local arch_pattern="$5"  # Optional: custom architecture pattern
  
  if [ -z "$repo" ] || [ -z "$version" ] || [ -z "$binary_name" ] || [ -z "$install_path" ]; then
    echo "Error: repo, version, binary_name, and install_path required"
    return 1
  fi
  
  # Get architecture
  local arch=$(get_architecture)
  
  # Use custom arch pattern if provided, otherwise use standard mapping
  if [ -n "$arch_pattern" ]; then
    arch="$arch_pattern"
  fi
  
  # Remove 'v' prefix from version if present
  version="${version#v}"
  
  local url="https://github.com/${repo}/releases/download/v${version}/${binary_name}"
  
  echo "Downloading $binary_name from $url..."
  if curl -fsSL "$url" -o "$install_path"; then
    chmod +x "$install_path"
    echo "✓ $binary_name installed successfully to $install_path"
    return 0
  else
    echo "✗ Failed to download $binary_name"
    rm -f "$install_path"
    return 1
  fi
}

# Secure download with checksum verification
secure_download() {
  local url="$1"
  local output_path="$2"
  local expected_checksum="$3"  # Optional: SHA256 checksum
  local checksum_url="$4"       # Optional: URL to checksum file
  
  if [ -z "$url" ] || [ -z "$output_path" ]; then
    echo "Error: URL and output path required"
    return 1
  fi
  
  echo "Downloading from $url..."
  if curl -fsSL "$url" -o "$output_path"; then
    # Verify checksum if provided
    if [ -n "$expected_checksum" ]; then
      echo "Verifying checksum..."
      local actual_checksum
      if command -v sha256sum >/dev/null 2>&1; then
        actual_checksum=$(sha256sum "$output_path" | cut -d' ' -f1)
      elif command -v shasum >/dev/null 2>&1; then
        actual_checksum=$(shasum -a 256 "$output_path" | cut -d' ' -f1)
      else
        echo "⚠️ No checksum utility available, skipping verification"
        return 0
      fi
      
      if [ "$actual_checksum" = "$expected_checksum" ]; then
        echo "✓ Checksum verification passed"
        return 0
      else
        echo "✗ Checksum verification failed"
        echo "  Expected: $expected_checksum"
        echo "  Actual:   $actual_checksum"
        rm -f "$output_path"
        return 1
      fi
    elif [ -n "$checksum_url" ]; then
      echo "Downloading and verifying checksum from $checksum_url..."
      local checksum_file="/tmp/$(basename "$output_path").checksum"
      if curl -fsSL "$checksum_url" -o "$checksum_file"; then
        # Extract checksum (handles various checksum file formats)
        local expected_checksum
        expected_checksum=$(grep -E "$(basename "$output_path")|^[a-f0-9]{64}" "$checksum_file" | head -1 | cut -d' ' -f1)
        rm -f "$checksum_file"
        
        if [ -n "$expected_checksum" ]; then
          # Recursive call with extracted checksum
          rm -f "$output_path"
          secure_download "$url" "$output_path" "$expected_checksum"
          return $?
        else
          echo "⚠️ Could not extract checksum from checksum file"
        fi
      else
        echo "⚠️ Failed to download checksum file, proceeding without verification"
      fi
    fi
    
    echo "✓ Download completed successfully"
    return 0
  else
    echo "✗ Failed to download from $url"
    rm -f "$output_path"
    return 1
  fi
}

# Check if we're in a non-interactive environment
is_non_interactive() {
  [ "$DEBIAN_FRONTEND" = "noninteractive" ] || [ -z "$TERM" ] || [ "$TERM" = "dumb" ]
}

cleanup_tmp() {
  echo "Cleaning up temporary files..."
  rm -f "$TMP_PKGS_FILE"
  rm -rf "$TMP_ALIASES_ROOT"
  rm -rf "$CONFIG_ROOT"
  rm -rf "$COMPLETION_ROOT"
}

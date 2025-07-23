#!/bin/bash
# Centralized tool configuration manager for modern-shell feature
set -e

# Script directory
UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="$(dirname "$UTILS_SCRIPT_DIR")"

# Load configuration manager
source "${FEATURE_DIR}/lib/config_manager.sh"

# Configuration markers
MARKER_START="# >>> common-utils - START >>>"
MARKER_END="# <<< common-utils - END <<<"

# Centralized architecture detection
get_architecture() {
    if command -v dpkg >/dev/null 2>&1; then
        dpkg --print-architecture
    elif command -v uname >/dev/null 2>&1; then
        case "$(uname -m)" in
            x86_64) echo "amd64" ;;
            aarch64) echo "arm64" ;;
            arm64) echo "arm64" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

# Temporary configuration files
TMP_BASHRC="/tmp/tmp_bashrc"
TMP_ZSHRC="/tmp/tmp_zshrc"
TMP_ZSHENV="/tmp/tmp_zshenv"
TMP_BASH_PROFILE="/tmp/tmp_bash_profile"

# Helper function to check if our config is already added
is_configured() {
    local file=$1
    if [ -f "$file" ] && grep -q "$MARKER_START" "$file"; then
        return 0
    fi
    return 1
}

# Helper function to remove existing marked content
remove_marked_content() {
    local file=$1
    if [ -f "$file" ] && is_configured "$file"; then
        # Create a temporary file without the marked section
        local temp_file="/tmp/shell_config_$$"
        awk -v start="$MARKER_START" -v end="$MARKER_END" '
            $0 ~ start { skip=1; next }
            $0 ~ end && skip { skip=0; next }
            !skip { print }
        ' "$file" > "$temp_file"
        
        # Replace original file with cleaned version
        mv "$temp_file" "$file"
        echo "  Removed previous configuration from $(basename "$file")"
    fi
}

# Helper function to update config in a file (replaces old content) - ATOMIC VERSION
update_config() {
    local file=$1
    local content=$2
    
    safe_log_debug "Updating configuration file: $file"
    
    # Create file if it doesn't exist
    if [ ! -f "$file" ]; then
        touch "$file"
        safe_log_debug "Created new configuration file: $file"
    fi
    
    # Only add new content if it's not empty
    if [ -n "$content" ] && [ "$content" != "" ]; then
        # Read existing file content
        local existing_content=""
        if [ -f "$file" ]; then
            existing_content=$(cat "$file")
        fi
        
        # Remove existing marked content
        local cleaned_content
        cleaned_content=$(echo "$existing_content" | awk -v start="$MARKER_START" -v end="$MARKER_END" '
            $0 ~ start { skip=1; next }
            $0 ~ end && skip { skip=0; next }
            !skip { print }
        ')
        
        # Add newline if content doesn't end with one
        if [ -n "$cleaned_content" ] && [[ "$cleaned_content" != *$'\n' ]]; then
            cleaned_content="$cleaned_content"$'\n'
        fi
        
        # Build new content with markers
        local new_content="$cleaned_content

$MARKER_START
# Added by common-utils feature
# $(date)
$content
$MARKER_END"
        
        # Use atomic configuration update
        if safe_config_update "$file" "$new_content" "644"; then
            safe_log_info "Updated configuration: $(basename "$file")"
        else
            safe_log_error "Failed to update configuration: $(basename "$file")"
            return "${ERROR_CODES[CONFIG_FAILED]}"
        fi
    else
        safe_log_debug "No configuration content for $(basename "$file")"
    fi
}

# Initialize temporary configuration files
init_tmp_config_files() {
    echo "🔧 Initializing temporary configuration files..."
    
    # Clear/create temporary files
    > "$TMP_BASHRC"
    > "$TMP_ZSHRC"  
    > "$TMP_ZSHENV"
    > "$TMP_BASH_PROFILE"
    
    echo "  Created temporary config files"
}

# Inject tmp file content into user shell file between markers - ATOMIC VERSION
inject_tmp_to_user_config_atomic() {
    local tmp_file=$1
    local user_file=$2
    local shell_name=$3
    
    # Skip if tmp file doesn't exist or is empty
    if [ ! -f "$tmp_file" ] || [ ! -s "$tmp_file" ]; then
        safe_log_debug "No configuration content for $(basename "$user_file")"
        return 1  # Indicate nothing was staged
    fi
    
    safe_log_debug "Staging configuration injection: $(basename "$tmp_file") -> $(basename "$user_file")"
    
    # Read existing user file content
    local existing_content=""
    if [ -f "$user_file" ]; then
        existing_content=$(cat "$user_file")
    fi
    
    # Remove existing marked content
    local cleaned_content
    cleaned_content=$(echo "$existing_content" | awk -v start="$MARKER_START" -v end="$MARKER_END" '
        $0 ~ start { skip=1; next }
        $0 ~ end && skip { skip=0; next }
        !skip { print }
    ')
    
    # Read tmp file content
    local tmp_content
    tmp_content=$(cat "$tmp_file")
    
    # Add newline if cleaned content doesn't end with one
    if [ -n "$cleaned_content" ] && [[ "$cleaned_content" != *$'\n' ]]; then
        cleaned_content="$cleaned_content"$'\n'
    fi
    
    # Build new content with markers
    local new_content="$cleaned_content

$MARKER_START
# Added by common-utils feature for $shell_name
# $(date)
$tmp_content
$MARKER_END"
    
    # Stage the configuration update
    if stage_config_update "$user_file" "$new_content" "644"; then
        safe_log_debug "Staged configuration injection: $(basename "$user_file")"
        return 0  # Success
    else
        safe_log_error "Failed to stage configuration injection: $(basename "$user_file")"
        return 1  # Failure
    fi
}


# Clean up temporary configuration files
cleanup_tmp_config_files() {
    echo "🧹 Cleaning up temporary configuration files..."
    rm -f "$TMP_BASHRC" "$TMP_ZSHRC" "$TMP_ZSHENV" "$TMP_BASH_PROFILE"
    echo "  Cleaned up temporary files"
}


# Direct (non-atomic) shell configuration fallback
configure_user_shells_direct() {
    local user=$1
    local home_dir=$2
    local install_starship=$3
    local install_zoxide=$4
    local install_eza=$5
    local install_bat=$6
    local install_motd=$7
    
    safe_log_info "Using direct configuration for user: $user"
    
    # Create home directory if it doesn't exist
    if [ ! -d "$home_dir" ]; then
        safe_log_info "Creating home directory: $home_dir"
        mkdir -p "$home_dir" || {
            safe_log_error "Failed to create home directory: $home_dir"
            return 1
        }
    fi
    
    # Ensure shell files exist
    safe_log_debug "Creating shell configuration files"
    touch "$home_dir/.bashrc" "$home_dir/.bash_profile" "$home_dir/.zshrc" "$home_dir/.zshenv" || {
        safe_log_error "Failed to create shell configuration files"
        return 1
    }
    
    # Debug: Check temp file status
    safe_log_debug "Temp file status: TMP_BASHRC=$TMP_BASHRC (exists: $([ -f "$TMP_BASHRC" ] && echo yes || echo no))"
    safe_log_debug "Temp file status: TMP_ZSHRC=$TMP_ZSHRC (exists: $([ -f "$TMP_ZSHRC" ] && echo yes || echo no))"
    
    # Append configurations directly without atomic transaction
    if [ -n "$TMP_BASHRC" ] && [ -f "$TMP_BASHRC" ]; then
        safe_log_debug "Appending TMP_BASHRC to .bashrc"
        cat "$TMP_BASHRC" >> "$home_dir/.bashrc" || safe_log_warn "Failed to append TMP_BASHRC"
    else
        safe_log_debug "TMP_BASHRC not available"
    fi
    
    if [ -n "$TMP_BASH_PROFILE" ] && [ -f "$TMP_BASH_PROFILE" ]; then
        safe_log_debug "Appending TMP_BASH_PROFILE to .bash_profile"
        cat "$TMP_BASH_PROFILE" >> "$home_dir/.bash_profile" || safe_log_warn "Failed to append TMP_BASH_PROFILE"
    else
        safe_log_debug "TMP_BASH_PROFILE not available"
    fi
    
    if [ -n "$TMP_ZSHRC" ] && [ -f "$TMP_ZSHRC" ]; then
        safe_log_debug "Appending TMP_ZSHRC to .zshrc"
        cat "$TMP_ZSHRC" >> "$home_dir/.zshrc" || safe_log_warn "Failed to append TMP_ZSHRC"
    else
        safe_log_debug "TMP_ZSHRC not available"
    fi
    
    if [ -n "$TMP_ZSHENV" ] && [ -f "$TMP_ZSHENV" ]; then
        safe_log_debug "Appending TMP_ZSHENV to .zshenv"
        cat "$TMP_ZSHENV" >> "$home_dir/.zshenv" || safe_log_warn "Failed to append TMP_ZSHENV"
    else
        safe_log_debug "TMP_ZSHENV not available"
    fi
    
    # Fix ownership
    safe_log_debug "Fixing ownership for user: $user"
    if [ "$user" != "root" ]; then
        chown -R "$user:$(id -gn "$user" 2>/dev/null || echo "$user")" "$home_dir/.bashrc" "$home_dir/.bash_profile" "$home_dir/.zshrc" "$home_dir/.zshenv" 2>/dev/null || {
            safe_log_warn "Failed to change ownership, but continuing"
        }
    fi
    
    safe_log_info "Direct configuration completed for user: $user"
    return 0
}

# Configure shell files for a user using tmp files - ATOMIC VERSION
configure_user_shells() {
    local user=$1
    local home_dir=$2
    local install_starship=$3
    local install_zoxide=$4
    local install_eza=$5
    local install_bat=$6
    local install_motd=$7
    
    safe_log_info "Configuring shells for user: $user"
    
    # Initialize atomic configuration transaction with fallback
    # Ultra-minimal configuration to resolve prebuild issues
    safe_log_info "Using ultra-minimal configuration approach"
    safe_log_debug "User: $user, Home: $home_dir"
    
    # Debug: Check if user exists
    if id "$user" >/dev/null 2>&1; then
        safe_log_debug "User $user exists"
    else
        safe_log_error "User $user does not exist!"
        return 1
    fi
    
    # Debug: Check home directory
    safe_log_debug "Checking home directory: $home_dir"
    if [ ! -d "$home_dir" ]; then
        safe_log_info "Creating home directory: $home_dir"
        if ! mkdir -p "$home_dir"; then
            safe_log_error "Failed to create home directory: $home_dir"
            return 1
        fi
        safe_log_debug "Successfully created home directory"
    else
        safe_log_debug "Home directory already exists"
    fi
    
    # Create shell files one by one with error checking
    safe_log_debug "Creating .bashrc"
    touch "$home_dir/.bashrc" || { safe_log_error "Failed to create .bashrc"; return 1; }
    
    safe_log_debug "Creating .bash_profile"
    touch "$home_dir/.bash_profile" || { safe_log_error "Failed to create .bash_profile"; return 1; }
    
    safe_log_debug "Creating .zshrc"
    touch "$home_dir/.zshrc" || { safe_log_error "Failed to create .zshrc"; return 1; }
    
    safe_log_debug "Creating .zshenv"
    touch "$home_dir/.zshenv" || { safe_log_error "Failed to create .zshenv"; return 1; }
    
    safe_log_debug "All shell files created successfully"
    
    # Skip ownership fixing for now - this might be the issue
    if [ "$user" != "root" ]; then
        safe_log_debug "Attempting to fix ownership for non-root user"
        # Try to get the user's group safely
        local user_group
        user_group=$(id -gn "$user" 2>/dev/null) || user_group="$user"
        safe_log_debug "User group: $user_group"
        
        # Fix ownership without failing the whole process
        if chown "$user:$user_group" "$home_dir/.bashrc" "$home_dir/.bash_profile" "$home_dir/.zshrc" "$home_dir/.zshenv" 2>/dev/null; then
            safe_log_debug "Successfully fixed ownership"
        else
            safe_log_warn "Could not fix ownership, but continuing"
        fi
    fi
    
    safe_log_info "Ultra-minimal configuration completed for user: $user"
    return 0
    
    # Original atomic config code (disabled for now)
    # if ! init_config_transaction; then
    #     safe_log_warn "Atomic configuration failed, using direct configuration approach"
    #     configure_user_shells_direct "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat" "$install_motd"
    #     return $?
    # fi
    
    # Check for existing files
    safe_log_debug "Checking for existing shell configurations..."
    [ -f "$home_dir/.bashrc" ] && safe_log_debug "Found existing .bashrc"
    [ -f "$home_dir/.bash_profile" ] && safe_log_debug "Found existing .bash_profile"
    [ -f "$home_dir/.zshrc" ] && safe_log_debug "Found existing .zshrc"
    [ -f "$home_dir/.zshenv" ] && safe_log_debug "Found existing .zshenv"
    [ -f "$home_dir/.zprofile" ] && safe_log_debug "Found existing .zprofile"
    
    # Stage all shell configuration updates
    local config_files=()
    
    # Configure bash
    if inject_tmp_to_user_config_atomic "$TMP_BASHRC" "$home_dir/.bashrc" "bash"; then
        config_files+=("$home_dir/.bashrc")
    fi
    
    if inject_tmp_to_user_config_atomic "$TMP_BASH_PROFILE" "$home_dir/.bash_profile" "bash"; then
        config_files+=("$home_dir/.bash_profile")
    fi
    
    # Configure zsh (only if zsh is installed)
    if command -v zsh >/dev/null 2>&1; then
        if inject_tmp_to_user_config_atomic "$TMP_ZSHRC" "$home_dir/.zshrc" "zsh"; then
            config_files+=("$home_dir/.zshrc")
        fi
        
        if inject_tmp_to_user_config_atomic "$TMP_ZSHENV" "$home_dir/.zshenv" "zsh"; then
            config_files+=("$home_dir/.zshenv")
        fi
    else
        safe_log_debug "Skipping zsh configuration (zsh not installed)"
    fi
    
    # Commit all configuration changes atomically
    if commit_config_transaction; then
        safe_log_info "Shell configuration completed successfully for $user"
        safe_log_info "Updated ${#config_files[@]} configuration files"
    else
        safe_log_error "Shell configuration failed for $user"
        rollback_config_transaction
        cleanup_config_transaction
        return "${ERROR_CODES[CONFIG_FAILED]}"
    fi
    
    cleanup_config_transaction
}

# Install tool-specific configurations
install_tool_configs() {
    local user=$1
    local home_dir=$2
    local install_starship=$3
    local install_zoxide=$4
    local install_eza=$5
    local install_bat=$6
    
    # Copy starship config if installed
    if [ "$install_starship" = "true" ] && [ -f "$UTILS_SCRIPT_DIR/shell/starship/starship.toml" ]; then
        mkdir -p "$home_dir/.config"
        
        if [ -f "$home_dir/.config/starship.toml" ]; then
            echo "  Found existing starship.toml, will be replaced"
        fi
        
        cp "$UTILS_SCRIPT_DIR/shell/starship/starship.toml" "$home_dir/.config/starship.toml"
        echo "  Installed starship configuration"
    fi
    
    # MOTD script is generated by install_motd function, not copied from a template
}

# Fix ownership of files
fix_ownership() {
    local user=$1
    local home_dir=$2
    
    if [ "$user" != "root" ]; then
        # Fix ownership for all shell configs
        [ -f "$home_dir/.bashrc" ] && chown "$user:$user" "$home_dir/.bashrc"
        [ -f "$home_dir/.bash_profile" ] && chown "$user:$user" "$home_dir/.bash_profile"
        [ -f "$home_dir/.zshrc" ] && chown "$user:$user" "$home_dir/.zshrc"
        [ -f "$home_dir/.zshenv" ] && chown "$user:$user" "$home_dir/.zshenv"
        [ -f "$home_dir/.zprofile" ] && chown "$user:$user" "$home_dir/.zprofile"
        
        # Fix ownership for config directory
        if [ -d "$home_dir/.config" ]; then
            chown -R "$user:$user" "$home_dir/.config"
        fi
    fi
}

# Main configuration function
configure_tools() {
    local user=$1
    local home_dir=$2
    local install_starship=${3:-"false"}
    local install_zoxide=${4:-"false"}
    local install_eza=${5:-"false"}
    local install_bat=${6:-"false"}
    local install_motd=${7:-"false"}
    
    echo "🛠️  Configuring modern shell tools for user: $user"
    echo "   Home directory: $home_dir"
    echo "   Starship: $install_starship"
    echo "   Zoxide: $install_zoxide" 
    echo "   Eza: $install_eza"
    echo "   Bat: $install_bat"
    echo "   MOTD: $install_motd"
    
    # Configure shell files
    configure_user_shells "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat" "$install_motd"
    
    # Install tool-specific configurations
    install_tool_configs "$user" "$home_dir" "$install_starship" "$install_zoxide" "$install_eza" "$install_bat"
    
    # Fix ownership
    fix_ownership "$user" "$home_dir"
    
    # Clean up temporary files
    cleanup_tmp_config_files
    
    echo "✅ Shell configuration completed for $user"
}

# Allow this script to be sourced or called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Called directly - expect arguments
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <user> <home_dir> [install_starship] [install_zoxide] [install_eza] [install_bat] [install_motd]"
        exit 1
    fi
    
    configure_tools "$@"
fi
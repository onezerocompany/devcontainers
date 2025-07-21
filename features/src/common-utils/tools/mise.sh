#!/bin/bash
set -e

# ========================================
# MISE CONFIGURATION
# ========================================
# Note: Mise installation is handled in the base image

# Function to add mise aliases to shell config files
configure_mise_aliases() {
    local config_file="$1"
    local marker_start="# >>> Mise aliases - START >>>"
    local marker_end="# <<< Mise aliases - END <<<"
    
    # Check if already configured
    if [ -f "$config_file" ] && grep -q "$marker_start" "$config_file"; then
        return 0
    fi
    
    # Create file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
    fi
    
    # Add newline if file doesn't end with one
    if [ -s "$config_file" ] && [ "$(tail -c 1 "$config_file")" != "" ]; then
        echo "" >> "$config_file"
    fi
    
    # Append mise aliases
    cat >> "$config_file" << EOF

$marker_start
# Mise aliases
alias tools='mise ls --current'
$marker_end
EOF
}

# Get mise aliases content for template replacement
get_mise_aliases() {
    cat << 'EOF'
# Mise aliases
alias tools='mise ls --current'
EOF
}
#!/bin/bash
# Script to remove Modern Shell Tools configuration from shell files
set -e

# Arguments
HOME_DIR="${1:-$HOME}"

# Markers for our additions
MARKER_START="# >>> Modern Shell Tools - START >>>"
MARKER_END="# <<< Modern Shell Tools - END <<<"

# Function to remove our config section from a file
remove_config() {
    local file=$1
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    if grep -q "$MARKER_START" "$file"; then
        # Create temp file without our section
        local temp_file="${file}.tmp"
        awk "
            /$MARKER_START/ {skip=1}
            /$MARKER_END/ {skip=0; next}
            !skip {print}
        " "$file" > "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$file"
        echo "  Cleaned $(basename "$file")"
    fi
}

echo "🧹 Removing Modern Shell Tools configuration..."

# Remove from all shell configs
remove_config "$HOME_DIR/.bashrc"
remove_config "$HOME_DIR/.bash_profile"
remove_config "$HOME_DIR/.zshrc"
remove_config "$HOME_DIR/.zshenv"
remove_config "$HOME_DIR/.zprofile"

echo "✅ Modern Shell Tools configuration removed"
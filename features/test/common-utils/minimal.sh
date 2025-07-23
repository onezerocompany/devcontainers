#!/bin/bash

# Test script for minimal common-utils configuration
# Tests with all bundles disabled - only basic zsh installation

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Test functions
test_basic_installation() {
    start_test_group "Basic Installation"
    
    assert_command_exists "zsh" "Zsh shell is installed"
    assert_user_exists "$DETECTED_USER" "User '$DETECTED_USER' exists"
    
    # Test that user's shell is set to zsh
    local user_shell
    user_shell=$(getent passwd "$DETECTED_USER" | cut -d: -f7)
    assert_command_output "echo '$user_shell'" "/usr/bin/zsh" "$DETECTED_USER user shell is zsh"
    
    end_test_group "Basic Installation"
}

test_bundles_disabled() {
    start_test_group "Bundle Tools Not Installed"
    
    # Shell bundle tools should not be installed
    assert_command_fails "command -v starship" "Starship is not installed"
    assert_command_fails "command -v bat" "Bat is not installed" 
    assert_command_fails "command -v eza" "Eza is not installed"
    assert_command_fails "command -v zoxide" "Zoxide is not installed"
    
    # Kubernetes tools should not be installed
    assert_command_fails "command -v kubectl" "Kubectl is not installed"
    assert_command_fails "command -v helm" "Helm is not installed"
    assert_command_fails "command -v k9s" "K9s is not installed"
    
    end_test_group "Bundle Tools Not Installed"
}

test_minimal_shell_config() {
    start_test_group "Minimal Shell Configuration"
    
    # Check that basic shell files exist
    local user_home="/home/$DETECTED_USER"
    if [[ "$DETECTED_USER" == "root" ]]; then
        user_home="/root"
    fi
    
    assert_file_exists "$user_home/.zshrc" "Basic zshrc exists for $DETECTED_USER"
    assert_file_exists "/root/.zshrc" "Basic zshrc exists for root"
    
    # Check that bundle-specific configs are not present
    assert_command_fails "grep -q 'starship init' '$user_home/.zshrc'" "No starship in zshrc"
    assert_command_fails "grep -q 'zoxide init' '$user_home/.zshrc'" "No zoxide in zshrc"
    
    end_test_group "Minimal Shell Configuration"
}

test_core_functionality() {
    start_test_group "Core Functionality"
    
    # Test that zsh works
    assert_command_succeeds "zsh --version" "Zsh version check"
    
    # Test basic shell functionality
    assert_command_succeeds "zsh -c 'echo \"test\"'" "Zsh execution test"
    
    end_test_group "Core Functionality"
}

# Main execution
main() {
    log_info "Starting minimal configuration tests for common-utils"
    
    # Run all test functions
    test_basic_installation
    test_bundles_disabled
    test_minimal_shell_config
    test_core_functionality
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
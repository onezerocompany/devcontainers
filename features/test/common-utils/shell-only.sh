#!/bin/bash

# Test script for shell-only common-utils configuration
# Tests with only shell bundle enabled

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Test functions
test_shell_installation() {
    start_test_group "Shell Installation"
    
    assert_command_exists "zsh" "Zsh shell is installed"
    assert_user_exists "$DETECTED_USER" "User '$DETECTED_USER' exists"
    
    # Test that user's shell is set to zsh
    local user_shell
    user_shell=$(getent passwd "$DETECTED_USER" | cut -d: -f7)
    assert_command_output "echo '$user_shell'" "/usr/bin/zsh" "$DETECTED_USER user shell is zsh"
    
    end_test_group "Shell Installation"
}

test_shell_bundle_tools() {
    start_test_group "Shell Bundle Tools"
    
    # Shell bundle tools should be installed
    assert_command_exists "starship" "Starship prompt is installed"
    assert_command_exists "bat" "Bat is installed"
    assert_command_exists "eza" "Eza is installed"
    assert_command_exists "zoxide" "Zoxide is installed"
    assert_command_exists "fd" "Fd is installed"
    assert_command_exists "rg" "Ripgrep is installed"
    
    end_test_group "Shell Bundle Tools"
}

test_other_bundles_disabled() {
    start_test_group "Other Bundles Not Installed"
    
    # Kubernetes tools should not be installed
    assert_command_fails "command -v kubectl" "Kubectl is not installed"
    assert_command_fails "command -v helm" "Helm is not installed"
    assert_command_fails "command -v k9s" "K9s is not installed"
    
    # Web dev tools should not be installed
    assert_command_fails "command -v http" "HTTPie is not installed"
    
    # Network tools should not be installed
    assert_command_fails "command -v nmap" "Nmap is not installed"
    
    end_test_group "Other Bundles Not Installed"
}

test_shell_configurations() {
    start_test_group "Shell Configurations"
    
    # Test detected user configuration
    check_user_shell_config "$DETECTED_USER"
    
    # Test root user configuration
    check_user_shell_config "root"
    
    # Check that shell tools are integrated
    local user_home="/home/$DETECTED_USER"
    if [[ "$DETECTED_USER" == "root" ]]; then
        user_home="/root"
    fi
    
    if [[ -f "$user_home/.zshrc" ]]; then
        assert_file_contains "$user_home/.zshrc" "starship init" "Starship is initialized in zshrc"
        assert_file_contains "$user_home/.zshrc" "zoxide init" "Zoxide is initialized in zshrc"
        assert_file_contains "$user_home/.zshrc" "alias ls='eza'" "Eza alias is set"
        assert_file_contains "$user_home/.zshrc" "alias cat='bat'" "Bat alias is set"
    fi
    
    end_test_group "Shell Configurations"
}

test_tool_functionality() {
    start_test_group "Tool Functionality"
    
    # Test that shell tools work
    assert_command_succeeds "starship --version" "Starship version check"
    assert_command_succeeds "bat --version" "Bat version check"
    assert_command_succeeds "eza --version" "Eza version check"
    assert_command_succeeds "fd --version" "Fd version check"
    assert_command_succeeds "rg --version" "Ripgrep version check"
    
    # Test zoxide functionality (requires initialization)
    assert_command_succeeds "zoxide --version" "Zoxide version check"
    
    end_test_group "Tool Functionality"
}

# Main execution
main() {
    log_info "Starting shell-only configuration tests for common-utils"
    
    # Run all test functions
    test_shell_installation
    test_shell_bundle_tools
    test_other_bundles_disabled
    test_shell_configurations 
    test_tool_functionality
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
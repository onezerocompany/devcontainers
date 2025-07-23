#!/bin/bash

# Test script for bash-shell common-utils configuration
# Tests with bash as default shell instead of zsh

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Test functions
test_bash_installation() {
    start_test_group "Bash Shell Configuration"
    
    # Zsh should not be installed when disabled
    assert_command_fails "command -v zsh" "Zsh is not installed"
    
    # Bash should be the default and present
    assert_command_exists "bash" "Bash shell is installed"
    assert_user_exists "$DETECTED_USER" "User '$DETECTED_USER' exists"
    
    # Test that user's shell is set to bash
    local user_shell
    user_shell=$(getent passwd "$DETECTED_USER" | cut -d: -f7)
    assert_command_output "echo '$user_shell'" "/bin/bash" "$DETECTED_USER user shell is bash"
    
    end_test_group "Bash Shell Configuration"
}

test_bash_configurations() {
    start_test_group "Bash Configuration Files"
    
    # Check that bash config files exist
    local user_home="/home/$DETECTED_USER"
    if [[ "$DETECTED_USER" == "root" ]]; then
        user_home="/root"
    fi
    
    assert_file_exists "$user_home/.bashrc" "Bashrc exists for $DETECTED_USER"
    assert_file_exists "/root/.bashrc" "Bashrc exists for root"
    
    # Zsh config files should not exist
    assert_command_fails "test -f '$user_home/.zshrc'" "No zshrc for $DETECTED_USER"
    assert_command_fails "test -f /root/.zshrc" "No zshrc for root"
    
    end_test_group "Bash Configuration Files"
}

test_shell_tools_with_bash() {
    start_test_group "Shell Tools with Bash"
    
    # Shell bundle tools should still be installed
    assert_command_exists "starship" "Starship prompt is installed"
    assert_command_exists "bat" "Bat is installed"
    assert_command_exists "eza" "Eza is installed"
    assert_command_exists "zoxide" "Zoxide is installed"
    
    # Check bash integration
    local user_home="/home/$DETECTED_USER"
    if [[ "$DETECTED_USER" == "root" ]]; then
        user_home="/root"
    fi
    
    if [[ -f "$user_home/.bashrc" ]]; then
        assert_file_contains "$user_home/.bashrc" "starship init bash" "Starship is initialized for bash"
        assert_file_contains "$user_home/.bashrc" "zoxide init bash" "Zoxide is initialized for bash"
        assert_file_contains "$user_home/.bashrc" "alias ls='eza'" "Eza alias is set in bashrc"
        assert_file_contains "$user_home/.bashrc" "alias cat='bat'" "Bat alias is set in bashrc"
    fi
    
    end_test_group "Shell Tools with Bash"
}

test_bash_functionality() {
    start_test_group "Bash Functionality"
    
    # Test that bash works
    assert_command_succeeds "bash --version" "Bash version check"
    
    # Test bash execution with shell tools
    assert_command_succeeds "bash -c 'starship --version'" "Starship works in bash"
    assert_command_succeeds "bash -c 'bat --version'" "Bat works in bash"
    assert_command_succeeds "bash -c 'eza --version'" "Eza works in bash"
    
    end_test_group "Bash Functionality"
}

test_starship_config() {
    start_test_group "Starship Configuration"
    
    # Starship config should exist for both users
    local user_home="/home/$DETECTED_USER"
    if [[ "$DETECTED_USER" == "root" ]]; then
        user_home="/root"
    fi
    
    assert_file_exists "$user_home/.config/starship.toml" "Starship config exists for $DETECTED_USER"
    assert_file_exists "/root/.config/starship.toml" "Starship config exists for root"
    
    end_test_group "Starship Configuration"
}

# Main execution
main() {
    log_info "Starting bash-shell configuration tests for common-utils"
    
    # Run all test functions
    test_bash_installation
    test_bash_configurations
    test_shell_tools_with_bash
    test_bash_functionality
    test_starship_config
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
#!/bin/bash

# Test script for individual-tools common-utils configuration
# Tests with bundles disabled but specific individual tools enabled

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
    
    end_test_group "Basic Installation"
}

test_individual_tools_installed() {
    start_test_group "Individual Tools Installed"
    
    # These specific tools should be installed
    assert_command_exists "bat" "Bat is installed (individual)"
    assert_command_exists "eza" "Eza is installed (individual)"
    assert_command_exists "starship" "Starship is installed (individual)"
    assert_command_exists "jq" "JQ is installed (individual)"
    assert_command_exists "kubectl" "Kubectl is installed (individual)"
    assert_command_exists "http" "HTTPie is installed (individual)"
    
    end_test_group "Individual Tools Installed"
}

test_bundle_tools_not_installed() {
    start_test_group "Bundle Tools Not Installed"
    
    # Tools from disabled bundles should not be installed
    assert_command_fails "command -v zoxide" "Zoxide is not installed (shell bundle disabled)"
    assert_command_fails "command -v fd" "Fd is not installed (shell bundle disabled)"
    assert_command_fails "command -v rg" "Ripgrep is not installed (shell bundle disabled)"
    
    # Utilities bundle tools should not be installed
    assert_command_fails "command -v tree" "Tree is not installed (utilities bundle disabled)"
    assert_command_fails "command -v htop" "Htop is not installed (utilities bundle disabled)"
    
    # Network tools should not be installed
    assert_command_fails "command -v nmap" "Nmap is not installed (networking bundle disabled)"
    
    # Additional kubernetes tools should not be installed
    assert_command_fails "command -v helm" "Helm is not installed (kubernetes bundle disabled)"
    assert_command_fails "command -v k9s" "K9s is not installed (kubernetes bundle disabled)"
    
    end_test_group "Bundle Tools Not Installed"
}

test_individual_tool_functionality() {
    start_test_group "Individual Tool Functionality"
    
    # Test that individually installed tools work
    assert_command_succeeds "bat --version" "Bat version check"
    assert_command_succeeds "eza --version" "Eza version check"
    assert_command_succeeds "starship --version" "Starship version check"
    assert_command_succeeds "jq --version" "JQ version check"
    assert_command_succeeds "kubectl version --client" "Kubectl version check"
    assert_command_succeeds "http --version" "HTTPie version check"
    
    end_test_group "Individual Tool Functionality"
}

test_partial_shell_configuration() {
    start_test_group "Partial Shell Configuration"
    
    # Check that basic shell files exist
    local user_home="/home/$DETECTED_USER"
    if [[ "$DETECTED_USER" == "root" ]]; then
        user_home="/root"
    fi
    
    assert_file_exists "$user_home/.zshrc" "Zshrc exists for $DETECTED_USER"
    assert_file_exists "/root/.zshrc" "Zshrc exists for root"
    
    # Check that installed tools are configured
    if [[ -f "$user_home/.zshrc" ]]; then
        assert_file_contains "$user_home/.zshrc" "starship init" "Starship is initialized in zshrc"
        assert_file_contains "$user_home/.zshrc" "alias ls='eza'" "Eza alias is set"
        assert_file_contains "$user_home/.zshrc" "alias cat='bat'" "Bat alias is set"
        
        # But disabled tools should not be configured
        assert_command_fails "grep -q 'zoxide init' '$user_home/.zshrc'" "No zoxide in zshrc"
    fi
    
    end_test_group "Partial Shell Configuration"
}

test_starship_configuration() {
    start_test_group "Starship Configuration"
    
    # Starship config should exist since starship is individually enabled
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
    log_info "Starting individual-tools configuration tests for common-utils"
    
    # Run all test functions
    test_basic_installation
    test_individual_tools_installed
    test_bundle_tools_not_installed
    test_individual_tool_functionality
    test_partial_shell_configuration
    test_starship_configuration
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
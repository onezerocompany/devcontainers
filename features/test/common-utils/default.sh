#!/bin/bash

# Test script for default common-utils configuration
# Tests the default bundle installation and configuration

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Test functions
test_zsh_installation() {
    start_test_group "Zsh Installation"
    
    assert_command_exists "zsh" "Zsh shell is installed"
    assert_user_exists "$DETECTED_USER" "User '$DETECTED_USER' exists"
    
    # Test that user's shell is set to zsh
    local user_shell
    user_shell=$(getent passwd "$DETECTED_USER" | cut -d: -f7)
    assert_command_output "echo '$user_shell'" "/usr/bin/zsh" "$DETECTED_USER user shell is zsh"
    
    end_test_group "Zsh Installation"
}

test_shell_bundle() {
    start_test_group "Shell Bundle"
    
    assert_command_exists "starship" "Starship prompt is installed"
    assert_command_exists "bat" "Bat is installed"
    assert_command_exists "eza" "Eza is installed"
    assert_command_exists "zoxide" "Zoxide is installed"
    assert_command_exists "fd" "Fd is installed"
    assert_command_exists "rg" "Ripgrep is installed"
    
    end_test_group "Shell Bundle"
}

test_utilities_bundle() {
    start_test_group "Utilities Bundle"
    
    assert_command_exists "curl" "Curl is installed"
    assert_command_exists "wget" "Wget is installed"
    assert_command_exists "zip" "Zip is installed"
    assert_command_exists "unzip" "Unzip is installed"
    assert_command_exists "tree" "Tree is installed"
    assert_command_exists "htop" "Htop is installed"
    assert_command_exists "vim" "Vim is installed"
    assert_command_exists "nano" "Nano is installed"
    
    end_test_group "Utilities Bundle"
}

test_networking_bundle() {
    start_test_group "Networking Bundle"
    
    assert_command_exists "nmap" "Nmap is installed"
    assert_command_exists "netcat" "Netcat is installed"
    assert_command_exists "dig" "DNS dig is installed"
    assert_command_exists "nslookup" "Nslookup is installed"
    assert_command_exists "whois" "Whois is installed"
    assert_command_exists "traceroute" "Traceroute is installed"
    assert_command_exists "ssh" "SSH client is installed"
    
    end_test_group "Networking Bundle"
}

test_kubernetes_bundle() {
    start_test_group "Kubernetes Bundle"
    
    assert_command_exists "kubectl" "Kubectl is installed"
    assert_command_exists "helm" "Helm is installed"
    assert_command_exists "k9s" "K9s is installed"
    assert_command_exists "kustomize" "Kustomize is installed"
    assert_command_exists "flux" "Flux is installed"
    assert_command_exists "kind" "Kind is installed"
    
    end_test_group "Kubernetes Bundle"
}

test_web_dev_bundle() {
    start_test_group "Web Development Bundle"
    
    assert_command_exists "http" "HTTPie is installed"
    assert_command_exists "psql" "PostgreSQL client is installed"
    assert_command_exists "redis-cli" "Redis CLI is installed"
    
    end_test_group "Web Development Bundle"
}

test_user_configurations() {
    start_test_group "User Configurations"
    
    # Test detected user configuration
    check_user_shell_config "$DETECTED_USER"
    
    # Test root user configuration
    check_user_shell_config "root"
    
    end_test_group "User Configurations"
}

test_shell_integrations() {
    start_test_group "Shell Integrations"
    
    # Test that shell tools are properly integrated
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
    
    end_test_group "Shell Integrations"
}

test_command_functionality() {
    start_test_group "Command Functionality"
    
    # Test that commands actually work
    assert_command_succeeds "starship --version" "Starship version check"
    assert_command_succeeds "bat --version" "Bat version check"
    assert_command_succeeds "eza --version" "Eza version check"
    assert_command_succeeds "kubectl version --client" "Kubectl client version"
    assert_command_succeeds "helm version" "Helm version check"
    
    end_test_group "Command Functionality"
}

# Main execution
main() {
    log_info "Starting default configuration tests for common-utils"
    
    # Run all test functions
    test_zsh_installation
    test_shell_bundle
    test_utilities_bundle
    test_networking_bundle
    test_kubernetes_bundle
    test_web_dev_bundle
    test_user_configurations
    test_shell_integrations
    test_command_functionality
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
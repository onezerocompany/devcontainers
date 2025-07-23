#!/bin/bash

# Test script for debian common-utils configuration
# Tests default configuration on Debian base image

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Test functions
test_debian_base() {
    start_test_group "Debian Base System"
    
    # Check that we're running on Debian
    assert_file_exists "/etc/debian_version" "Debian version file exists"
    assert_command_exists "apt" "APT package manager is available"
    
    end_test_group "Debian Base System"
}

test_zsh_installation_debian() {
    start_test_group "Zsh Installation on Debian"
    
    assert_command_exists "zsh" "Zsh shell is installed"
    assert_user_exists "$DETECTED_USER" "User '$DETECTED_USER' exists"
    
    # Test that user's shell is set to zsh
    local user_shell
    user_shell=$(getent passwd "$DETECTED_USER" | cut -d: -f7)
    assert_command_output "echo '$user_shell'" "/usr/bin/zsh" "$DETECTED_USER user shell is zsh"
    
    end_test_group "Zsh Installation on Debian"
}

test_shell_tools_debian() {
    start_test_group "Shell Tools on Debian"
    
    # All shell tools should work on Debian
    assert_command_exists "starship" "Starship prompt is installed"
    assert_command_exists "bat" "Bat is installed"
    assert_command_exists "eza" "Eza is installed"
    assert_command_exists "zoxide" "Zoxide is installed"
    assert_command_exists "fd" "Fd is installed"
    assert_command_exists "rg" "Ripgrep is installed"
    
    end_test_group "Shell Tools on Debian"
}

test_package_management_tools() {
    start_test_group "Package Management Tools"
    
    # Debian-specific tools should be available
    assert_command_exists "dpkg" "Dpkg is available"
    assert_command_exists "apt-get" "Apt-get is available"
    assert_command_exists "apt-cache" "Apt-cache is available"
    
    end_test_group "Package Management Tools"
}

test_kubernetes_tools_debian() {
    start_test_group "Kubernetes Tools on Debian"
    
    assert_command_exists "kubectl" "Kubectl is installed"
    assert_command_exists "helm" "Helm is installed"
    assert_command_exists "k9s" "K9s is installed"
    assert_command_exists "kustomize" "Kustomize is installed"
    
    end_test_group "Kubernetes Tools on Debian"
}

test_networking_tools_debian() {
    start_test_group "Networking Tools on Debian"
    
    assert_command_exists "curl" "Curl is installed"
    assert_command_exists "wget" "Wget is installed"
    assert_command_exists "dig" "DNS dig is installed"
    assert_command_exists "nslookup" "Nslookup is installed"
    assert_command_exists "nmap" "Nmap is installed"
    assert_command_exists "netcat" "Netcat is installed"
    
    end_test_group "Networking Tools on Debian"
}

test_user_configuration_debian() {
    start_test_group "User Configuration on Debian"
    
    # Test detected user configuration
    check_user_shell_config "$DETECTED_USER"
    
    # Test root user configuration
    check_user_shell_config "root"
    
    end_test_group "User Configuration on Debian"
}

test_debian_specific_functionality() {
    start_test_group "Debian-Specific Functionality"
    
    # Test that tools work correctly on Debian
    assert_command_succeeds "starship --version" "Starship version check"
    assert_command_succeeds "bat --version" "Bat version check"
    assert_command_succeeds "eza --version" "Eza version check"
    assert_command_succeeds "kubectl version --client" "Kubectl client version"
    assert_command_succeeds "helm version" "Helm version check"
    
    # Test Debian package system integration
    assert_command_succeeds "dpkg -l | grep -q zsh" "Zsh package is installed via dpkg"
    
    end_test_group "Debian-Specific Functionality"
}

# Main execution
main() {
    log_info "Starting Debian configuration tests for common-utils"
    
    # Run all test functions
    test_debian_base
    test_zsh_installation_debian
    test_shell_tools_debian
    test_package_management_tools
    test_kubernetes_tools_debian
    test_networking_tools_debian
    test_user_configuration_debian
    test_debian_specific_functionality
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
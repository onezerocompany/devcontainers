#!/bin/bash

# Test script for all-bundles common-utils configuration
# Tests with all bundles enabled

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source testing utilities
source "$SCRIPT_DIR/utils.sh"

# Test functions
test_shell_bundle() {
    check_shell_tools
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
    assert_command_exists "rsync" "Rsync is installed"
    
    end_test_group "Utilities Bundle"
}

test_networking_bundle() {
    check_network_tools
    
    start_test_group "Additional Network Tools"
    
    assert_command_exists "nmap" "Nmap is installed"
    assert_command_exists "netcat" "Netcat is installed"
    assert_command_exists "traceroute" "Traceroute is installed"
    assert_command_exists "whois" "Whois is installed"
    assert_command_exists "ssh" "SSH client is installed"
    
    end_test_group "Additional Network Tools"
}

test_kubernetes_bundle() {
    check_container_tools
    
    start_test_group "Additional Kubernetes Tools"
    
    assert_command_exists "k9s" "K9s is installed"
    assert_command_exists "kustomize" "Kustomize is installed"
    assert_command_exists "flux" "Flux is installed"
    assert_command_exists "kind" "Kind is installed"
    
    end_test_group "Additional Kubernetes Tools"
}

test_web_dev_bundle() {
    start_test_group "Web Development Bundle"
    
    assert_command_exists "http" "HTTPie is installed"
    assert_command_exists "psql" "PostgreSQL client is installed"
    assert_command_exists "redis-cli" "Redis CLI is installed"
    
    end_test_group "Web Development Bundle"
}

test_data_processing_bundle() {
    start_test_group "Data Processing Bundle"
    
    assert_command_exists "jq" "JQ is installed"
    assert_command_exists "yq" "YQ is installed"
    assert_command_exists "dasel" "Dasel is installed"
    assert_command_exists "mlr" "Miller is installed"
    
    end_test_group "Data Processing Bundle"
}

test_development_bundle() {
    start_test_group "Development Bundle"
    
    assert_command_exists "git" "Git is installed"
    assert_command_exists "gh" "GitHub CLI is installed"
    assert_command_exists "glab" "GitLab CLI is installed"
    assert_command_exists "task" "Task runner is installed"
    assert_command_exists "just" "Just runner is installed"
    assert_command_exists "make" "Make is installed"
    assert_command_exists "cmake" "CMake is installed"
    
    end_test_group "Development Bundle"
}

test_containers_bundle() {
    start_test_group "Containers Bundle"
    
    assert_command_exists "podman" "Podman is installed"
    assert_command_exists "buildah" "Buildah is installed"
    assert_command_exists "crane" "Crane is installed"
    assert_command_exists "dive" "Dive is installed"
    assert_command_exists "trivy" "Trivy is installed"
    assert_command_exists "docker-compose" "Docker Compose is installed"
    
    end_test_group "Containers Bundle"
}

test_comprehensive_functionality() {
    start_test_group "Comprehensive Functionality"
    
    # Test a sampling of tools from each bundle
    assert_command_succeeds "starship --version" "Starship functionality"
    assert_command_succeeds "kubectl version --client" "Kubectl functionality"
    assert_command_succeeds "helm version" "Helm functionality"
    assert_command_succeeds "jq --version" "JQ functionality"
    assert_command_succeeds "yq --version" "YQ functionality"
    assert_command_succeeds "gh --version" "GitHub CLI functionality"
    assert_command_succeeds "podman --version" "Podman functionality"
    assert_command_succeeds "http --version" "HTTPie functionality"
    
    end_test_group "Comprehensive Functionality"
}

test_user_configurations() {
    start_test_group "User Configurations"
    
    # Test detected user configuration
    check_user_shell_config "$DETECTED_USER"
    
    # Test root user configuration
    check_user_shell_config "root"
    
    end_test_group "User Configurations"
}

# Main execution
main() {
    log_info "Starting all-bundles configuration tests for common-utils"
    
    # Run all test functions
    test_shell_bundle
    test_utilities_bundle
    test_networking_bundle
    test_kubernetes_bundle
    test_web_dev_bundle
    test_data_processing_bundle
    test_development_bundle
    test_containers_bundle
    test_comprehensive_functionality
    test_user_configurations
    
    # Print final summary
    print_test_summary
}

# Execute main function
main "$@"
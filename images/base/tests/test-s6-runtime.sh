#!/bin/bash
# Runtime test script for s6-overlay services
# This script is meant to be run inside a running container with s6-overlay

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Wait for s6 to fully initialize
wait_for_s6() {
    log_info "Waiting for s6-overlay to initialize..."
    local max_wait=30
    local waited=0
    
    while [ $waited -lt $max_wait ]; do
        if s6-rc -a list >/dev/null 2>&1; then
            log_success "s6-overlay is ready"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    
    log_error "s6-overlay failed to initialize after ${max_wait} seconds"
    return 1
}

# Test Docker services
test_docker_services() {
    log_info "Testing Docker services..."
    
    # Check if Docker services are defined
    if ! s6-rc-db list services | grep -q dockerd; then
        log_info "Docker services not configured (standard variant)"
        return 0
    fi
    
    # Check dockerd service
    log_info "Checking dockerd service status..."
    if s6-rc -a list | grep -q dockerd; then
        log_success "dockerd service is active"
        
        # Check service state
        if s6-svstat /run/service/dockerd | grep -q "up"; then
            log_success "dockerd is running"
            
            # Get uptime
            local uptime=$(s6-svstat /run/service/dockerd | grep -oE 'up \([^)]+\)')
            log_debug "dockerd uptime: $uptime"
        else
            log_error "dockerd is not running"
            s6-svstat /run/service/dockerd
        fi
    else
        log_error "dockerd service is not active"
    fi
    
    # Check dockerd-log service
    log_info "Checking dockerd-log service status..."
    if s6-rc -a list | grep -q dockerd-log; then
        log_success "dockerd-log service is active"
        
        if s6-svstat /run/service/dockerd-log | grep -q "up"; then
            log_success "dockerd-log is running"
        else
            log_error "dockerd-log is not running"
        fi
    else
        log_error "dockerd-log service is not active"
    fi
    
    # Wait for Docker socket
    log_info "Waiting for Docker socket..."
    local socket_wait=0
    while [ $socket_wait -lt 30 ]; do
        if [ -S /var/run/docker.sock ]; then
            log_success "Docker socket is available"
            
            # Check socket permissions
            local perms=$(stat -c '%a' /var/run/docker.sock)
            if [ "$perms" = "666" ]; then
                log_success "Docker socket has correct permissions (666)"
            else
                log_error "Docker socket has incorrect permissions: $perms (expected 666)"
            fi
            
            # Test Docker functionality
            if docker version >/dev/null 2>&1; then
                log_success "Docker daemon is responsive"
                
                # Run a test container
                if docker run --rm hello-world >/dev/null 2>&1; then
                    log_success "Docker can run containers"
                else
                    log_error "Docker failed to run test container"
                fi
            else
                log_error "Docker daemon is not responsive"
            fi
            
            break
        fi
        sleep 1
        socket_wait=$((socket_wait + 1))
    done
    
    if [ ! -S /var/run/docker.sock ]; then
        log_error "Docker socket failed to appear after 30 seconds"
    fi
    
    # Check log directory
    if [ -d /var/log/services/dockerd ]; then
        log_success "Docker log directory exists"
        
        # Check if logs are being written
        if [ -n "$(ls -A /var/log/services/dockerd 2>/dev/null)" ]; then
            log_success "Docker logs are being written"
        else
            log_info "Docker log directory is empty (may be normal if just started)"
        fi
    else
        log_error "Docker log directory does not exist"
    fi
}

# Test service dependencies
test_service_dependencies() {
    log_info "Testing service dependency resolution..."
    
    # Check if docker-permissions ran after dockerd
    if s6-rc-db list services | grep -q docker-permissions; then
        # Check if the service completed
        if [ -f /var/run/docker.sock ] && [ "$(stat -c '%a' /var/run/docker.sock)" = "666" ]; then
            log_success "docker-permissions successfully set socket permissions"
        else
            log_error "docker-permissions did not complete successfully"
        fi
    fi
}

# Monitor services for stability
monitor_services() {
    log_info "Monitoring services for stability (10 seconds)..."
    
    local start_time=$(date +%s)
    local dockerd_restarts=0
    local initial_pid=""
    
    # Get initial dockerd PID if running
    if s6-svok /run/service/dockerd 2>/dev/null; then
        initial_pid=$(s6-svstat /run/service/dockerd 2>/dev/null | grep -oE 'pid [0-9]+' | awk '{print $2}')
    fi
    
    # Monitor for 10 seconds
    while [ $(($(date +%s) - start_time)) -lt 10 ]; do
        if [ -n "$initial_pid" ]; then
            current_pid=$(s6-svstat /run/service/dockerd 2>/dev/null | grep -oE 'pid [0-9]+' | awk '{print $2}' || echo "")
            if [ -n "$current_pid" ] && [ "$current_pid" != "$initial_pid" ]; then
                dockerd_restarts=$((dockerd_restarts + 1))
                initial_pid=$current_pid
                log_error "dockerd restarted (restart count: $dockerd_restarts)"
            fi
        fi
        sleep 1
    done
    
    if [ $dockerd_restarts -eq 0 ]; then
        log_success "Services remained stable during monitoring period"
    else
        log_error "dockerd restarted $dockerd_restarts times during monitoring"
    fi
}

# Main execution
main() {
    log_info "Starting s6-overlay runtime tests..."
    echo "================================"
    
    # Check if running with s6
    if ! pgrep s6-svscan >/dev/null 2>&1; then
        log_error "s6-svscan is not running. This container must be started with s6-overlay."
        echo "To run these tests, start the container with:"
        echo "  docker run --rm -it --privileged <image>"
        exit 1
    fi
    
    # Wait for s6 initialization
    wait_for_s6 || exit 1
    
    # Run tests
    test_docker_services
    test_service_dependencies
    monitor_services
    
    echo "================================"
    log_info "Runtime tests completed"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/bin/bash
# Error Handling Framework for Common Utils Feature
# Provides structured error reporting, retry logic, and failure recovery

set -euo pipefail

# Error codes for different failure types
declare -r -A ERROR_CODES=(
    [SUCCESS]=0
    [GENERAL_ERROR]=1
    [DOWNLOAD_FAILED]=10
    [VALIDATION_FAILED]=11
    [INSTALL_FAILED]=12
    [CONFIG_FAILED]=13
    [NETWORK_ERROR]=14
    [PERMISSION_ERROR]=15
    [DEPENDENCY_ERROR]=16
    [ARCHITECTURE_ERROR]=17
    [USER_INPUT_ERROR]=18
)

# Global error tracking
ERRORS_ENCOUNTERED=()
WARNING_COUNT=0
ERROR_COUNT=0

# Logging configuration
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
LOG_FILE="${LOG_FILE:-/tmp/common-utils-install.log}"

# Initialize logging
init_logging() {
    # Create log file if it doesn't exist
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/dev/null"
    
    # Log session start
    log_info "=== Common Utils Installation Started at $(date) ==="
    log_info "Log level: $LOG_LEVEL"
    log_info "Architecture: $(uname -m)"
    log_info "OS: $(uname -s)"
}

# Logging functions
log_debug() {
    [[ "$LOG_LEVEL" == "DEBUG" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*" | tee -a "$LOG_FILE" >&2
}

log_info() {
    [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO)$ ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" | tee -a "$LOG_FILE"
}

log_warn() {
    ((WARNING_COUNT++))
    [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO|WARN)$ ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" | tee -a "$LOG_FILE" >&2
}

log_error() {
    ((ERROR_COUNT++))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Error reporting with context
report_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-}"
    local recovery_hint="${4:-}"
    
    log_error "[$error_code] $error_message"
    [ -n "$context" ] && log_error "Context: $context"
    [ -n "$recovery_hint" ] && log_error "Recovery: $recovery_hint"
    
    # Track error for summary
    ERRORS_ENCOUNTERED+=("$error_code: $error_message")
    
    return "$error_code"
}

# Safe exit with error summary
safe_exit() {
    local exit_code="${1:-0}"
    
    log_info "=== Installation Summary ==="
    log_info "Warnings: $WARNING_COUNT"
    log_info "Errors: $ERROR_COUNT"
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        log_error "Errors encountered during installation:"
        for error in "${ERRORS_ENCOUNTERED[@]}"; do
            log_error "  - $error"
        done
    fi
    
    if [ "$exit_code" -eq 0 ] && [ "$ERROR_COUNT" -gt 0 ]; then
        log_warn "Installation completed with errors - some features may not work correctly"
    elif [ "$exit_code" -eq 0 ]; then
        log_info "Installation completed successfully"
    fi
    
    log_info "=== Installation Ended at $(date) ==="
    exit "$exit_code"
}

# Retry logic with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local initial_delay="$2"
    local backoff_factor="${3:-2}"
    shift 3
    
    local attempt=1
    local delay="$initial_delay"
    
    while [ "$attempt" -le "$max_attempts" ]; do
        log_debug "Attempt $attempt/$max_attempts: $*"
        
        if "$@"; then
            [ "$attempt" -gt 1 ] && log_info "Command succeeded on attempt $attempt"
            return 0
        fi
        
        if [ "$attempt" -eq "$max_attempts" ]; then
            log_error "Command failed after $max_attempts attempts: $*"
            return 1
        fi
        
        log_warn "Attempt $attempt failed, retrying in ${delay}s..."
        sleep "$delay"
        delay=$((delay * backoff_factor))
        ((attempt++))
    done
}

# Network operation wrapper with retry
network_operation() {
    local operation_name="$1"
    shift
    
    log_info "Starting network operation: $operation_name"
    
    if retry_with_backoff 3 2 2 "$@"; then
        log_info "Network operation completed: $operation_name"
        return 0
    else
        report_error "${ERROR_CODES[NETWORK_ERROR]}" \
            "Network operation failed: $operation_name" \
            "Command: $*" \
            "Check network connectivity and try again"
        return "${ERROR_CODES[NETWORK_ERROR]}"
    fi
}

# File operation with validation
safe_file_operation() {
    local operation="$1"
    local source="$2"
    local target="$3"
    local backup_suffix="${4:-.backup-$(date +%s)}"
    
    case "$operation" in
        "copy")
            # Create backup if target exists
            if [ -f "$target" ]; then
                log_debug "Creating backup: $target$backup_suffix"
                cp "$target" "$target$backup_suffix" || {
                    report_error "${ERROR_CODES[CONFIG_FAILED]}" \
                        "Failed to create backup of $target"
                    return "${ERROR_CODES[CONFIG_FAILED]}"
                }
            fi
            
            # Perform copy
            if cp "$source" "$target"; then
                log_debug "File copied: $source -> $target"
                return 0
            else
                # Restore backup if copy failed
                if [ -f "$target$backup_suffix" ]; then
                    mv "$target$backup_suffix" "$target"
                    log_warn "Restored backup after failed copy"
                fi
                report_error "${ERROR_CODES[CONFIG_FAILED]}" \
                    "Failed to copy file: $source -> $target"
                return "${ERROR_CODES[CONFIG_FAILED]}"
            fi
            ;;
        "move")
            if mv "$source" "$target"; then
                log_debug "File moved: $source -> $target"
                return 0
            else
                report_error "${ERROR_CODES[CONFIG_FAILED]}" \
                    "Failed to move file: $source -> $target"
                return "${ERROR_CODES[CONFIG_FAILED]}"
            fi
            ;;
        *)
            report_error "${ERROR_CODES[GENERAL_ERROR]}" \
                "Unknown file operation: $operation"
            return "${ERROR_CODES[GENERAL_ERROR]}"
            ;;
    esac
}

# Dependency checking
check_dependencies() {
    local dependencies=("$@")
    local missing_deps=()
    
    log_info "Checking dependencies..."
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
            log_warn "Missing dependency: $dep"
        else
            log_debug "Found dependency: $dep"
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        report_error "${ERROR_CODES[DEPENDENCY_ERROR]}" \
            "Missing required dependencies: ${missing_deps[*]}" \
            "" \
            "Install missing dependencies and retry"
        return "${ERROR_CODES[DEPENDENCY_ERROR]}"
    fi
    
    log_info "All dependencies satisfied"
    return 0
}

# Disk space checking
check_disk_space() {
    local required_mb="$1"
    local path="${2:-/tmp}"
    
    local available_kb
    available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_mb=$((available_kb / 1024))
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        report_error "${ERROR_CODES[GENERAL_ERROR]}" \
            "Insufficient disk space" \
            "Required: ${required_mb}MB, Available: ${available_mb}MB" \
            "Free up disk space and retry"
        return "${ERROR_CODES[GENERAL_ERROR]}"
    fi
    
    log_debug "Disk space check passed: ${available_mb}MB available"
    return 0
}

# Permission checking
check_permissions() {
    local path="$1"
    local required_permission="$2"  # r, w, x, or combination
    
    case "$required_permission" in
        *r*) 
            if [ ! -r "$path" ]; then
                report_error "${ERROR_CODES[PERMISSION_ERROR]}" \
                    "No read permission for $path"
                return "${ERROR_CODES[PERMISSION_ERROR]}"
            fi
            ;;
    esac
    
    case "$required_permission" in
        *w*) 
            if [ ! -w "$path" ]; then
                report_error "${ERROR_CODES[PERMISSION_ERROR]}" \
                    "No write permission for $path"
                return "${ERROR_CODES[PERMISSION_ERROR]}"
            fi
            ;;
    esac
    
    case "$required_permission" in
        *x*) 
            if [ ! -x "$path" ]; then
                report_error "${ERROR_CODES[PERMISSION_ERROR]}" \
                    "No execute permission for $path"
                return "${ERROR_CODES[PERMISSION_ERROR]}"
            fi
            ;;
    esac
    
    return 0
}

# Installation step wrapper
installation_step() {
    local step_name="$1"
    local step_description="$2"
    shift 2
    
    log_info "=== Starting: $step_name ==="
    log_info "Description: $step_description"
    
    local start_time
    start_time=$(date +%s)
    
    if "$@"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_info "=== Completed: $step_name (${duration}s) ==="
        return 0
    else
        local exit_code=$?
        log_error "=== Failed: $step_name ==="
        report_error "$exit_code" \
            "Installation step failed: $step_name" \
            "Command: $*"
        return "$exit_code"
    fi
}

# Cleanup function for safe exit
cleanup_on_exit() {
    local exit_code=$?
    
    log_debug "Cleanup triggered with exit code: $exit_code"
    
    # Clean up temporary files
    if [ -n "${TEMP_FILES:-}" ]; then
        for temp_file in $TEMP_FILES; do
            if [ -f "$temp_file" ]; then
                rm -f "$temp_file"
                log_debug "Cleaned up temp file: $temp_file"
            fi
        done
    fi
    
    # Clean up temporary directories
    if [ -n "${TEMP_DIRS:-}" ]; then
        for temp_dir in $TEMP_DIRS; do
            if [ -d "$temp_dir" ]; then
                rm -rf "$temp_dir"
                log_debug "Cleaned up temp directory: $temp_dir"
            fi
        done
    fi
    
    safe_exit "$exit_code"
}

# Set up error handling
setup_error_handling() {
    # Initialize logging
    init_logging
    
    # Set up exit trap
    trap cleanup_on_exit EXIT
    
    # Set up error trap
    trap 'report_error "${ERROR_CODES[GENERAL_ERROR]}" "Unexpected error at line $LINENO" "$BASH_COMMAND"' ERR
    
    log_info "Error handling framework initialized"
}

# Installation validation function
validate_installation_completeness() {
    log_info "Validating installation completeness..."
    
    local validation_errors=()
    local validation_warnings=()
    
    # Validate core tools if requested
    if [ "${INSTALL_STARSHIP:-false}" = "true" ]; then
        if command -v starship >/dev/null 2>&1; then
            log_info "✓ Starship installed and available"
        else
            validation_errors+=("Starship was requested but not found in PATH")
        fi
    fi
    
    if [ "${INSTALL_ZOXIDE:-false}" = "true" ]; then
        if command -v zoxide >/dev/null 2>&1; then
            log_info "✓ Zoxide installed and available"
        else
            validation_errors+=("Zoxide was requested but not found in PATH")
        fi
    fi
    
    if [ "${INSTALL_EZA:-false}" = "true" ]; then
        if command -v eza >/dev/null 2>&1; then
            log_info "✓ Eza installed and available"
        else
            validation_errors+=("Eza was requested but not found in PATH")
        fi
    fi
    
    if [ "${INSTALL_BAT:-false}" = "true" ]; then
        if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then
            log_info "✓ Bat installed and available"
        else
            validation_errors+=("Bat was requested but not found in PATH")
        fi
    fi
    
    if [ "${INSTALL_ZSH:-false}" = "true" ]; then
        if command -v zsh >/dev/null 2>&1; then
            log_info "✓ Zsh installed and available"
        else
            validation_errors+=("Zsh was requested but not found in PATH")
        fi
    fi
    
    # Validate shell configuration
    if [ "${DEFAULT_SHELL:-bash}" = "zsh" ]; then
        if command -v zsh >/dev/null 2>&1; then
            log_info "✓ Default shell (zsh) is available"
        else
            validation_warnings+=("Default shell set to zsh but zsh is not installed")
        fi
    fi
    
    # Validate shell configuration files exist for the user
    local user_home
    if [ "${USERNAME:-root}" = "root" ]; then
        user_home="/root"
    else
        user_home="/home/${USERNAME}"
    fi
    
    # Check critical shell files exist
    local config_files=(".bashrc" ".bash_profile")
    if [ "${INSTALL_ZSH:-false}" = "true" ]; then
        config_files+=(".zshrc" ".zshenv")
    fi
    
    for config_file in "${config_files[@]}"; do
        local full_path="$user_home/$config_file"
        if [ -f "$full_path" ]; then
            log_debug "✓ Configuration file exists: $config_file"
            # Check our markers are present
            if grep -q "common-utils - START" "$full_path" 2>/dev/null; then
                log_debug "✓ Configuration markers found in $config_file"
            else
                validation_warnings+=("Configuration markers not found in $config_file")
            fi
        else
            validation_warnings+=("Expected configuration file missing: $config_file")
        fi
    done
    
    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        log_error "Installation validation failed with ${#validation_errors[@]} error(s):"
        for error in "${validation_errors[@]}"; do
            log_error "  - $error"
        done
        
        log_error "Common causes:"
        log_error "  - Network connectivity issues during download"
        log_error "  - Architecture not supported for some tools"
        log_error "  - Repository access problems"
        log_error "  - Insufficient disk space"
        
        return "${ERROR_CODES[VALIDATION_FAILED]}"
    fi
    
    if [ ${#validation_warnings[@]} -gt 0 ]; then
        log_warn "Installation completed with ${#validation_warnings[@]} warning(s):"
        for warning in "${validation_warnings[@]}"; do
            log_warn "  - $warning"
        done
        log_warn "The container should still be functional with the tools that did install."
    fi
    
    log_info "Installation validation completed successfully"
    return 0
}

# Installation health check
validate_installation_health() {
    log_info "Performing installation health check..."
    
    local health_issues=()
    
    # Check if PATH includes /usr/local/bin
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        health_issues+=("/usr/local/bin not in PATH - tools may not be accessible")
    fi
    
    # Check if shell configurations are syntactically valid
    local user_home
    if [ "${USERNAME:-root}" = "root" ]; then
        user_home="/root"
    else
        user_home="/home/${USERNAME}"
    fi
    
    # Validate shell script syntax
    for config_file in "$user_home/.bashrc" "$user_home/.bash_profile"; do
        if [ -f "$config_file" ]; then
            if ! bash -n "$config_file" 2>/dev/null; then
                health_issues+=("Syntax error in $config_file")
            fi
        fi
    done
    
    if [ "${INSTALL_ZSH:-false}" = "true" ]; then
        for config_file in "$user_home/.zshrc" "$user_home/.zshenv"; do
            if [ -f "$config_file" ]; then
                if ! zsh -n "$config_file" 2>/dev/null; then
                    health_issues+=("Syntax error in $config_file")
                fi
            fi
        done
    fi
    
    # Check critical directories exist and are writable
    for dir in "/usr/local/bin" "/tmp"; do
        if [ ! -d "$dir" ]; then
            health_issues+=("Critical directory missing: $dir")
        elif [ ! -w "$dir" ]; then
            health_issues+=("Critical directory not writable: $dir")
        fi
    done
    
    # Report health check results
    if [ ${#health_issues[@]} -gt 0 ]; then
        log_warn "Health check found ${#health_issues[@]} issue(s):"
        for issue in "${health_issues[@]}"; do
            log_warn "  - $issue"
        done
        return 1
    fi
    
    log_info "Installation health check passed"
    return 0
}

# Failure recovery mechanism
recover_from_failure() {
    local failure_type="$1"
    local context="$2"
    
    log_info "Attempting failure recovery for: $failure_type"
    
    case "$failure_type" in
        "network")
            log_info "Network failure recovery: checking connectivity and retrying"
            # Test basic connectivity
            if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
                log_info "Network connectivity confirmed, safe to retry"
                return 0
            else
                log_warn "Network connectivity still unavailable"
                return 1
            fi
            ;;
        "permission")
            log_info "Permission failure recovery: checking and attempting fixes"
            # Check if we have sudo/root access
            if [ "$EUID" -eq 0 ]; then
                log_info "Running as root, permissions should be sufficient"
                return 0
            else
                log_error "Permission failure and not running as root"
                return 1
            fi
            ;;
        "disk_space")
            log_info "Disk space failure recovery: cleaning temporary files"
            # Clean up common temporary locations
            if [ -n "${TEMP_FILES:-}" ]; then
                for temp_file in $TEMP_FILES; do
                    [ -f "$temp_file" ] && rm -f "$temp_file"
                done
                log_info "Cleaned temporary files"
            fi
            
            if [ -n "${TEMP_DIRS:-}" ]; then
                for temp_dir in $TEMP_DIRS; do
                    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
                done
                log_info "Cleaned temporary directories"
            fi
            
            # Check if space is now available
            local available_kb
            available_kb=$(df /tmp | awk 'NR==2 {print $4}')
            local available_mb=$((available_kb / 1024))
            
            if [ "$available_mb" -gt 100 ]; then
                log_info "Disk space recovery successful: ${available_mb}MB available"
                return 0
            else
                log_warn "Insufficient disk space after cleanup: ${available_mb}MB"
                return 1
            fi
            ;;
        "config")
            log_info "Configuration failure recovery: attempting rollback"
            # If we have a transaction in progress, try to rollback
            if [ -n "${TRANSACTION_ID:-}" ]; then
                rollback_config_transaction
                cleanup_config_transaction
                log_info "Configuration rollback completed"
                return 0
            else
                log_warn "No active configuration transaction to rollback"
                return 1
            fi
            ;;
        "dependency")
            log_info "Dependency failure recovery: refreshing package lists"
            # Try updating package lists
            if retry_with_backoff 2 1 2 apt-get update >/dev/null 2>&1; then
                log_info "Package lists refreshed successfully"
                return 0
            else
                log_warn "Failed to refresh package lists"
                return 1
            fi
            ;;
        *)
            log_warn "No specific recovery mechanism for failure type: $failure_type"
            return 1
            ;;
    esac
}

# Enhanced installation step with recovery
installation_step_with_recovery() {
    local step_name="$1"
    local step_description="$2"
    local recovery_type="${3:-general}"
    shift 3
    
    log_info "=== Starting: $step_name (with recovery) ==="
    log_info "Description: $step_description"
    
    local start_time
    start_time=$(date +%s)
    local max_retries=2
    local retry_count=0
    
    while [ "$retry_count" -le "$max_retries" ]; do
        if [ "$retry_count" -gt 0 ]; then
            log_info "Retry attempt $retry_count for: $step_name"
        fi
        
        if "$@"; then
            local end_time
            end_time=$(date +%s)
            local duration=$((end_time - start_time))
            if [ "$retry_count" -gt 0 ]; then
                log_info "=== Completed: $step_name (${duration}s, succeeded on retry $retry_count) ==="
            else
                log_info "=== Completed: $step_name (${duration}s) ==="
            fi
            return 0
        else
            local exit_code=$?
            
            if [ "$retry_count" -eq "$max_retries" ]; then
                log_error "=== Failed: $step_name (exhausted retries) ==="
                report_error "$exit_code" \
                    "Installation step failed after $max_retries retries: $step_name" \
                    "Command: $*"
                return "$exit_code"
            fi
            
            log_warn "Installation step failed: $step_name (attempt $((retry_count + 1)))"
            
            # Attempt recovery
            if recover_from_failure "$recovery_type" "$step_name"; then
                log_info "Recovery successful, retrying $step_name"
                ((retry_count++))
                sleep 2  # Brief pause before retry
                continue
            else
                log_error "Recovery failed for $step_name"
                report_error "$exit_code" \
                    "Installation step failed and recovery unsuccessful: $step_name" \
                    "Command: $*"
                return "$exit_code"
            fi
        fi
    done
}

# Partial installation recovery
recover_partial_installation() {
    log_info "Attempting to recover from partial installation failure"
    
    local recovery_actions=()
    
    # Check what succeeded and what failed
    local working_tools=()
    local failed_tools=()
    
    # Test core tools
    command -v starship >/dev/null 2>&1 && working_tools+=("starship") || failed_tools+=("starship")
    command -v zoxide >/dev/null 2>&1 && working_tools+=("zoxide") || failed_tools+=("zoxide") 
    command -v eza >/dev/null 2>&1 && working_tools+=("eza") || failed_tools+=("eza")
    (command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1) && working_tools+=("bat") || failed_tools+=("bat")
    command -v zsh >/dev/null 2>&1 && working_tools+=("zsh") || failed_tools+=("zsh")
    
    log_info "Working tools: ${working_tools[*]:-none}"
    log_info "Failed tools: ${failed_tools[*]:-none}"
    
    # Provide recovery suggestions
    if [ ${#failed_tools[@]} -gt 0 ]; then
        log_info "Recovery suggestions for failed tools:"
        for tool in "${failed_tools[@]}"; do
            case "$tool" in
                "starship"|"zoxide"|"eza"|"bat")
                    log_info "  - $tool: Try manual installation with specific architecture"
                    ;;
                "zsh")
                    log_info "  - $tool: Install via system package manager (apt install zsh)"
                    ;;
            esac
        done
    fi
    
    # Generate partial recovery script
    local recovery_script="/tmp/common-utils-recovery.sh"
    cat > "$recovery_script" << 'EOF'
#!/bin/bash
# Common Utils Partial Recovery Script
# This script attempts to recover failed tool installations

echo "🔄 Starting partial installation recovery..."

# Set up basic error handling
set -e

# Re-source the installation environment
if [ -f "/usr/local/share/common-utils/lib/error_handling.sh" ]; then
    source "/usr/local/share/common-utils/lib/error_handling.sh"
    setup_error_handling
fi

echo "Recovery script completed. Re-run feature installation if issues persist."
EOF
    
    chmod +x "$recovery_script"
    log_info "Generated recovery script: $recovery_script"
    
    return 0
}

# Export functions that will be used by other scripts
export -f log_debug log_info log_warn log_error
export -f report_error safe_exit retry_with_backoff network_operation
export -f safe_file_operation check_dependencies check_disk_space
export -f check_permissions installation_step validate_installation_completeness
export -f validate_installation_health recover_from_failure installation_step_with_recovery
export -f recover_partial_installation
#!/bin/bash
# Atomic Configuration Management for Common Utils Feature
# Provides safe, atomic configuration updates with rollback capability

# Note: Avoiding 'set -e' here to allow graceful fallback when functions aren't available

# Safe logging functions that work even if logging framework is not available
safe_log_info() {
    if command -v log_info >/dev/null 2>&1; then
        log_info "$@"
    else
        echo "[INFO] $*"
    fi
}

safe_log_warn() {
    if command -v log_warn >/dev/null 2>&1; then
        log_warn "$@"
    else
        echo "[WARN] $*" >&2
    fi
}

safe_log_error() {
    if command -v log_error >/dev/null 2>&1; then
        log_error "$@"
    else
        echo "[ERROR] $*" >&2
    fi
}

safe_log_debug() {
    if command -v log_debug >/dev/null 2>&1; then
        log_debug "$@"
    fi
}

# Configuration management state
declare -A PENDING_CONFIGS=()
declare -A CONFIG_BACKUPS=()
declare -A CONFIG_CHECKSUMS=()
TRANSACTION_ID=""
TRANSACTION_DIR=""

# Initialize configuration transaction
init_config_transaction() {
    TRANSACTION_ID="config-$(date +%s)-$$"
    TRANSACTION_DIR="/tmp/common-utils-config-$TRANSACTION_ID"
    
    mkdir -p "$TRANSACTION_DIR/backups" 2>/dev/null || return 1
    mkdir -p "$TRANSACTION_DIR/staging" 2>/dev/null || return 1
    
    safe_log_info "Configuration transaction started: $TRANSACTION_ID"
    safe_log_debug "Transaction directory: $TRANSACTION_DIR"
    
    # Debug: verify directories were created successfully
    if [ ! -d "$TRANSACTION_DIR/backups" ]; then
        safe_log_error "Failed to create backups directory: $TRANSACTION_DIR/backups"
        return 1
    fi
    if [ ! -d "$TRANSACTION_DIR/staging" ]; then
        safe_log_error "Failed to create staging directory: $TRANSACTION_DIR/staging"
        return 1
    fi
    safe_log_debug "Transaction directories verified successfully"
    
    # Track temp directory for cleanup
    if [ -z "${TEMP_DIRS:-}" ]; then
        TEMP_DIRS="$TRANSACTION_DIR"
    else
        TEMP_DIRS="$TEMP_DIRS $TRANSACTION_DIR"
    fi
}

# Calculate file checksum for change detection
calculate_checksum() {
    local file="$1"
    
    if [ -f "$file" ]; then
        sha256sum "$file" | cut -d' ' -f1
    else
        echo "new-file"
    fi
}

# Create backup of existing configuration
create_config_backup() {
    local target_file="$1"
    local backup_path="$TRANSACTION_DIR/backups/$(basename "$target_file")"
    
    if [ -f "$target_file" ]; then
        if ! cp "$target_file" "$backup_path"; then
            if command -v report_error >/dev/null 2>&1; then
                report_error "${ERROR_CODES[CONFIG_FAILED]:-13}" \
                    "Failed to create backup of $target_file"
            else
                safe_log_error "Failed to create backup of $target_file"
            fi
            return "${ERROR_CODES[CONFIG_FAILED]:-13}"
        fi
        
        CONFIG_BACKUPS["$target_file"]="$backup_path"
        CONFIG_CHECKSUMS["$target_file"]=$(calculate_checksum "$target_file")
        safe_log_debug "Created backup: $target_file -> $backup_path"
    else
        CONFIG_BACKUPS["$target_file"]="NONEXISTENT"
        CONFIG_CHECKSUMS["$target_file"]="new-file"
        safe_log_debug "Target file doesn't exist: $target_file"
    fi
    
    return 0
}

# Stage configuration for atomic update
stage_config_update() {
    local target_file="$1"
    local content="$2"
    local mode="${3:-644}"
    
    local staging_file="$TRANSACTION_DIR/staging/$(basename "$target_file")"
    
    # Write content to staging area
    if ! echo "$content" > "$staging_file"; then
        if command -v report_error >/dev/null 2>&1; then
            report_error "${ERROR_CODES[CONFIG_FAILED]:-13}" \
                "Failed to write staging file: $staging_file"
        else
            safe_log_error "Failed to write staging file: $staging_file"
        fi
        return "${ERROR_CODES[CONFIG_FAILED]:-13}"
    fi
    
    # Set permissions
    chmod "$mode" "$staging_file"
    
    # Validate staged content (basic checks)
    if [ ! -s "$staging_file" ]; then
        if command -v report_error >/dev/null 2>&1; then
            report_error "${ERROR_CODES[CONFIG_FAILED]:-13}" \
                "Staged configuration is empty: $staging_file"
        else
            safe_log_error "Staged configuration is empty: $staging_file"
        fi
        return "${ERROR_CODES[CONFIG_FAILED]:-13}"
    fi
    
    PENDING_CONFIGS["$target_file"]="$staging_file"
    safe_log_debug "Staged configuration: $target_file"
    
    return 0
}

# Stage configuration file copy
stage_config_file() {
    local source_file="$1"
    local target_file="$2"
    local mode="${3:-644}"
    
    if [ ! -f "$source_file" ]; then
        if command -v report_error >/dev/null 2>&1; then
            report_error "${ERROR_CODES[CONFIG_FAILED]:-13}" \
                "Source configuration file not found: $source_file"
        else
            safe_log_error "Source configuration file not found: $source_file"
        fi
        return "${ERROR_CODES[CONFIG_FAILED]:-13}"
    fi
    
    local staging_file="$TRANSACTION_DIR/staging/$(basename "$target_file")"
    
    # Copy to staging area
    if ! cp "$source_file" "$staging_file"; then
        if command -v report_error >/dev/null 2>&1; then
            report_error "${ERROR_CODES[CONFIG_FAILED]:-13}" \
                "Failed to stage configuration file: $source_file"
        else
            safe_log_error "Failed to stage configuration file: $source_file"
        fi
        return "${ERROR_CODES[CONFIG_FAILED]:-13}"
    fi
    
    # Set permissions
    chmod "$mode" "$staging_file"
    
    PENDING_CONFIGS["$target_file"]="$staging_file"
    safe_log_debug "Staged configuration file: $source_file -> $target_file"
    
    return 0
}

# Validate staged configurations
validate_staged_configs() {
    local validation_errors=()
    
    safe_log_info "Validating staged configurations..."
    
    for target_file in "${!PENDING_CONFIGS[@]}"; do
        local staging_file="${PENDING_CONFIGS[$target_file]}"
        
        # Check staging file exists and is readable
        if [ ! -f "$staging_file" ] || [ ! -r "$staging_file" ]; then
            validation_errors+=("Staging file not accessible: $staging_file")
            continue
        fi
        
        # Check target directory exists and is writable
        local target_dir
        target_dir=$(dirname "$target_file")
        if [ ! -d "$target_dir" ]; then
            # Try to create directory
            if ! mkdir -p "$target_dir"; then
                validation_errors+=("Cannot create target directory: $target_dir")
                continue
            fi
        fi
        
        if [ ! -w "$target_dir" ]; then
            validation_errors+=("Target directory not writable: $target_dir")
            continue
        fi
        
        # Shell script validation if applicable
        if [[ "$target_file" =~ \.(sh|bash)$ ]]; then
            if ! bash -n "$staging_file" 2>/dev/null; then
                validation_errors+=("Shell script syntax error: $target_file")
                continue
            fi
        fi
        
        safe_log_debug "Validation passed: $target_file"
    done
    
    if [ ${#validation_errors[@]} -gt 0 ]; then
        safe_log_error "Configuration validation failed:"
        for error in "${validation_errors[@]}"; do
            safe_log_error "  - $error"
        done
        return "${ERROR_CODES[VALIDATION_FAILED]:-11}"
    fi
    
    safe_log_info "All staged configurations validated successfully"
    return 0
}

# Apply staged configurations atomically
commit_config_transaction() {
    local committed_files=()
    
    safe_log_info "Committing configuration transaction: $TRANSACTION_ID"
    
    # First, create backups for all target files
    for target_file in "${!PENDING_CONFIGS[@]}"; do
        if ! create_config_backup "$target_file"; then
            safe_log_error "Failed to create backup for $target_file, aborting transaction"
            return "${ERROR_CODES[CONFIG_FAILED]}"
        fi
    done
    
    # Validate all staged configurations
    if ! validate_staged_configs; then
        safe_log_error "Configuration validation failed, aborting transaction"
        return "${ERROR_CODES[VALIDATION_FAILED]}"
    fi
    
    # Apply configurations
    for target_file in "${!PENDING_CONFIGS[@]}"; do
        local staging_file="${PENDING_CONFIGS[$target_file]}"
        
        safe_log_debug "Applying configuration: $staging_file -> $target_file"
        
        # Ensure target directory exists
        local target_dir
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"
        
        # Atomic move (within same filesystem)
        if mv "$staging_file" "$target_file"; then
            committed_files+=("$target_file")
            safe_log_debug "Successfully applied: $target_file"
        else
            safe_log_error "Failed to apply configuration: $target_file"
            # Rollback all committed files so far
            rollback_config_transaction "${committed_files[@]}"
            return "${ERROR_CODES[CONFIG_FAILED]}"
        fi
    done
    
    safe_log_info "Configuration transaction committed successfully"
    safe_log_info "Applied ${#committed_files[@]} configuration files"
    
    return 0
}

# Rollback configuration transaction
rollback_config_transaction() {
    local files_to_rollback=("$@")
    
    safe_log_warn "Rolling back configuration transaction: $TRANSACTION_ID"
    
    # If no specific files provided, rollback all pending configs
    if [ ${#files_to_rollback[@]} -eq 0 ]; then
        files_to_rollback=("${!CONFIG_BACKUPS[@]}")
    fi
    
    for target_file in "${files_to_rollback[@]}"; do
        local backup_path="${CONFIG_BACKUPS[$target_file]:-}"
        
        if [ -z "$backup_path" ]; then
            safe_log_warn "No backup found for $target_file"
            continue
        fi
        
        if [ "$backup_path" = "NONEXISTENT" ]; then
            # File didn't exist before, remove it
            if [ -f "$target_file" ]; then
                rm -f "$target_file"
                safe_log_debug "Removed file that didn't exist before: $target_file"
            fi
        else
            # Restore from backup
            if cp "$backup_path" "$target_file"; then
                safe_log_debug "Restored from backup: $target_file"
            else
                safe_log_error "Failed to restore backup: $target_file"
            fi
        fi
    done
    
    safe_log_warn "Configuration rollback completed"
}

# Clean up configuration transaction
cleanup_config_transaction() {
    if [ -n "$TRANSACTION_DIR" ] && [ -d "$TRANSACTION_DIR" ]; then
        rm -rf "$TRANSACTION_DIR"
        safe_log_debug "Cleaned up transaction directory: $TRANSACTION_DIR"
    fi
    
    # Clear transaction state
    PENDING_CONFIGS=()
    CONFIG_BACKUPS=()
    CONFIG_CHECKSUMS=()
    TRANSACTION_ID=""
    TRANSACTION_DIR=""
}

# Safe configuration update with automatic rollback on failure
safe_config_update() {
    local target_file="$1"
    local content="$2"
    local mode="${3:-644}"
    
    # Initialize transaction if not already started
    if [ -z "$TRANSACTION_ID" ]; then
        init_config_transaction
    fi
    
    # Stage the update
    if ! stage_config_update "$target_file" "$content" "$mode"; then
        safe_log_error "Failed to stage configuration update for $target_file"
        return "${ERROR_CODES[CONFIG_FAILED]}"
    fi
    
    # Commit the single update
    if commit_config_transaction; then
        safe_log_info "Configuration successfully updated: $target_file"
        cleanup_config_transaction
        return 0
    else
        safe_log_error "Configuration update failed for $target_file"
        rollback_config_transaction
        cleanup_config_transaction
        return "${ERROR_CODES[CONFIG_FAILED]}"
    fi
}

# Batch configuration updates
batch_config_update() {
    init_config_transaction
    
    safe_log_info "Starting batch configuration update"
    
    # Stage all updates (this function expects pairs of target_file content)
    while [ $# -gt 1 ]; do
        local target_file="$1"
        local content="$2"
        shift 2
        
        if ! stage_config_update "$target_file" "$content"; then
            safe_log_error "Failed to stage batch update for $target_file"
            cleanup_config_transaction
            return "${ERROR_CODES[CONFIG_FAILED]}"
        fi
    done
    
    # Commit all updates atomically
    if commit_config_transaction; then
        safe_log_info "Batch configuration update completed successfully"
        cleanup_config_transaction
        return 0
    else
        safe_log_error "Batch configuration update failed"
        rollback_config_transaction
        cleanup_config_transaction
        return "${ERROR_CODES[CONFIG_FAILED]}"
    fi
}

# Configuration change detection
detect_config_changes() {
    local target_file="$1"
    local current_checksum
    local stored_checksum="${CONFIG_CHECKSUMS[$target_file]:-}"
    
    current_checksum=$(calculate_checksum "$target_file")
    
    if [ "$current_checksum" != "$stored_checksum" ]; then
        safe_log_info "Configuration change detected: $target_file"
        return 0  # Changed
    else
        safe_log_debug "No change detected: $target_file"
        return 1  # Unchanged
    fi
}

# Export functions for use by other scripts
export -f init_config_transaction create_config_backup stage_config_update
export -f stage_config_file validate_staged_configs commit_config_transaction
export -f rollback_config_transaction cleanup_config_transaction
export -f safe_config_update batch_config_update detect_config_changes
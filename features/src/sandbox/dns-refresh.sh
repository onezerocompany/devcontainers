#!/bin/bash
# DNS Refresh Daemon for Sandbox Network Filter
# Periodically updates iptables rules when DNS resolutions change
set -e

REFRESH_INTERVAL="${DNS_REFRESH_INTERVAL:-300}" # Default 5 minutes
LOG_FILE="/var/log/sandbox-dns-refresh.log"
PID_FILE="/var/run/sandbox-dns-refresh.pid"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if we're running as daemon
is_daemon() {
    [ "$1" = "--daemon" ]
}

# Function to start daemon
start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log "DNS refresh daemon already running (PID: $(cat "$PID_FILE"))"
        exit 1
    fi
    
    log "Starting DNS refresh daemon (interval: ${REFRESH_INTERVAL}s)"
    echo $$ > "$PID_FILE"
    
    # Trap to clean up PID file on exit
    trap 'rm -f "$PID_FILE"; log "DNS refresh daemon stopped"' EXIT
    
    while true; do
        refresh_dns_rules
        sleep "$REFRESH_INTERVAL"
    done
}

# Function to stop daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "Stopping DNS refresh daemon (PID: $pid)"
            kill "$pid"
            rm -f "$PID_FILE"
            log "DNS refresh daemon stopped"
        else
            log "DNS refresh daemon not running"
            rm -f "$PID_FILE"
        fi
    else
        log "DNS refresh daemon not running (no PID file)"
    fi
}

# Function to get current IPs from iptables rules
get_current_sandbox_ips() {
    iptables_cmd -t filter -L SANDBOX_OUTPUT -n 2>/dev/null | \
    grep -E "ACCEPT.*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | \
    sed -n 's/.*\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/p' | \
    sort -u
}

# Function to resolve domain to IPs with caching
resolve_domain_cached() {
    local domain="$1"
    local cache_file="/tmp/dns-cache-${domain//[^a-zA-Z0-9]/_}"
    local cache_ttl=300 # 5 minutes
    
    # Check if cache exists and is fresh
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0))) -lt $cache_ttl ]; then
        cat "$cache_file"
        return
    fi
    
    # Resolve and cache
    local ips
    ips=$(timeout 5 dig +short +time=2 +tries=1 "$domain" A 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || true)
    
    if [ -n "$ips" ]; then
        echo "$ips" > "$cache_file"
        echo "$ips"
    fi
}

# Function to refresh DNS rules
refresh_dns_rules() {
    log "Starting DNS refresh cycle"
    
    # Load configuration
    if [ -f /etc/sandbox/config ]; then
        source /etc/sandbox/config
    fi
    
    # Determine if we need sudo
    if [ -z "$USE_SUDO" ]; then
        if [ "$EUID" -ne 0 ]; then
            USE_SUDO=1
        else
            USE_SUDO=0
        fi
    fi
    
    # Create iptables wrapper functions
    iptables_cmd() {
        if [ "$USE_SUDO" = "1" ]; then
            sudo iptables "$@"
        else
            iptables "$@"
        fi
    }
    
    # Check if sandbox chain exists
    if ! iptables_cmd -t filter -L SANDBOX_OUTPUT >/dev/null 2>&1; then
        log "SANDBOX_OUTPUT chain not found, skipping refresh"
        return
    fi
    
    local changes_made=0
    local domains_to_check=()
    
    # Collect domains from various sources
    if [ "$ALLOW_COMMON_DEVELOPMENT" = "true" ] && [ -f "/usr/local/share/sandbox/common-domains.txt" ]; then
        while IFS= read -r domain; do
            # Skip comments and empty lines
            [[ "$domain" =~ ^#.*$ ]] || [[ -z "$domain" ]] && continue
            domains_to_check+=("$domain")
        done < "/usr/local/share/sandbox/common-domains.txt"
    fi
    
    # Add custom allowed domains
    if [ -n "$ALLOWED_DOMAINS" ]; then
        IFS=',' read -ra DOMAIN_LIST <<< "$ALLOWED_DOMAINS"
        for domain in "${DOMAIN_LIST[@]}"; do
            domain=$(echo "$domain" | xargs)
            [ -n "$domain" ] && domains_to_check+=("$domain")
        done
    fi
    
    # Get current IPs in iptables
    local current_ips
    current_ips=($(get_current_sandbox_ips))
    
    # Create associative array for current IPs
    declare -A current_ip_set
    for ip in "${current_ips[@]}"; do
        current_ip_set["$ip"]=1
    done
    
    # Resolve all domains and collect new IPs
    declare -A new_ip_set
    for domain in "${domains_to_check[@]}"; do
        # Skip wildcard domains for now (more complex)
        [[ "$domain" == \*.* ]] && continue
        
        local resolved_ips
        resolved_ips=$(resolve_domain_cached "$domain")
        
        if [ -n "$resolved_ips" ]; then
            while IFS= read -r ip; do
                [ -n "$ip" ] && new_ip_set["$ip"]=1
            done <<< "$resolved_ips"
        fi
    done
    
    # Find IPs to add (in new set but not in current set)
    for ip in "${!new_ip_set[@]}"; do
        if [ -z "${current_ip_set[$ip]}" ]; then
            log "Adding new IP: $ip"
            iptables_cmd -t filter -I SANDBOX_OUTPUT -d "$ip" -j ACCEPT
            changes_made=1
        fi
    done
    
    # Find IPs to remove (in current set but not in new set)
    # Only remove IPs that were added by domain resolution (not static rules)
    for ip in "${!current_ip_set[@]}"; do
        if [ -z "${new_ip_set[$ip]}" ] && ! is_static_ip "$ip"; then
            log "Removing stale IP: $ip"
            iptables_cmd -t filter -D SANDBOX_OUTPUT -d "$ip" -j ACCEPT 2>/dev/null || true
            changes_made=1
        fi
    done
    
    if [ $changes_made -eq 1 ]; then
        log "DNS refresh completed with changes"
        # Save rules if immutable config is enabled
        if [ "$IMMUTABLE_CONFIG" = "true" ]; then
            if [ "$USE_SUDO" = "1" ]; then
                sudo iptables-save > /etc/iptables/rules.v4
            else
                iptables-save > /etc/iptables/rules.v4
            fi
        fi
    else
        log "DNS refresh completed - no changes needed"
    fi
}

# Function to check if IP is from static rules (localhost, docker networks, etc.)
is_static_ip() {
    local ip="$1"
    
    # Check if it's localhost
    [[ "$ip" =~ ^127\. ]] && return 0
    
    # Check if it's Docker networks
    [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[01])\. ]] && return 0
    [[ "$ip" =~ ^10\. ]] && return 0
    [[ "$ip" =~ ^192\.168\. ]] && return 0
    
    # Check if it's DNS servers (common ones)
    case "$ip" in
        "8.8.8.8"|"8.8.4.4"|"1.1.1.1"|"1.0.0.1") return 0 ;;
    esac
    
    return 1
}

# Function to show status
show_status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "DNS refresh daemon is running (PID: $(cat "$PID_FILE"))"
        echo "Refresh interval: ${REFRESH_INTERVAL}s"
        echo "Log file: $LOG_FILE"
        if [ -f "$LOG_FILE" ]; then
            echo "Last 5 log entries:"
            tail -n 5 "$LOG_FILE"
        fi
    else
        echo "DNS refresh daemon is not running"
    fi
}

# Main script logic
case "${1:-}" in
    --daemon)
        start_daemon
        ;;
    --start)
        # Test iptables access before starting daemon
        if [ "$EUID" -ne 0 ]; then
            if ! sudo iptables -L OUTPUT >/dev/null 2>&1; then
                echo "ERROR: Cannot access iptables with sudo. DNS refresh daemon cannot start."
                exit 1
            fi
            echo "DNS refresh daemon will use sudo for iptables access"
        else
            if ! iptables -L OUTPUT >/dev/null 2>&1; then
                echo "ERROR: Cannot access iptables as root. DNS refresh daemon cannot start."
                exit 1
            fi
            echo "DNS refresh daemon running as root"
        fi
        
        nohup "$0" --daemon > /var/log/sandbox-dns-refresh.log 2>&1 &
        echo "DNS refresh daemon started in background (PID: $!)"
        echo "Logs: /var/log/sandbox-dns-refresh.log"
        ;;
    --stop)
        stop_daemon
        ;;
    --restart)
        stop_daemon
        sleep 2
        nohup "$0" --daemon > /dev/null 2>&1 &
        echo "DNS refresh daemon restarted"
        ;;
    --status)
        show_status
        ;;
    --refresh)
        refresh_dns_rules
        ;;
    *)
        echo "Usage: $0 {--start|--stop|--restart|--status|--refresh|--daemon}"
        echo ""
        echo "Commands:"
        echo "  --start     Start DNS refresh daemon in background"
        echo "  --stop      Stop DNS refresh daemon"
        echo "  --restart   Restart DNS refresh daemon"
        echo "  --status    Show daemon status"
        echo "  --refresh   Perform one-time DNS refresh"
        echo "  --daemon    Run as daemon (internal use)"
        echo ""
        echo "Environment variables:"
        echo "  DNS_REFRESH_INTERVAL  Refresh interval in seconds (default: 300)"
        exit 1
        ;;
esac
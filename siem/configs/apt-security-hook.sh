# APT Hook for Package Management Monitoring
# This script logs all package operations for security monitoring

log_file="/var/log/apt/security-audit.log"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$log_file")"

# Function to log package operations
log_package_operation() {
    local operation="$1"
    local package="$2"
    local version="$3"
    local user="${SUDO_USER:-$USER}"
    
    echo "[$timestamp] PACKAGE_AUDIT: operation=$operation package=$package version=$version user=$user pid=$$ ppid=$PPID" >> "$log_file"
    
    # Send to syslog for centralized logging
    logger -t "APT_SECURITY_AUDIT" "operation=$operation package=$package version=$version user=$user"
}

# Pre-install hook
if [ "$1" = "pre-install" ]; then
    log_package_operation "pre-install" "$2" "$3"
fi

# Post-install hook
if [ "$1" = "post-install" ]; then
    log_package_operation "post-install" "$2" "$3"
fi

# Pre-remove hook
if [ "$1" = "pre-remove" ]; then
    log_package_operation "pre-remove" "$2" "$3"
fi

# Post-remove hook
if [ "$1" = "post-remove" ]; then
    log_package_operation "post-remove" "$2" "$3"
fi

# Pre-upgrade hook
if [ "$1" = "pre-upgrade" ]; then
    log_package_operation "pre-upgrade" "$2" "$3"
fi

# Post-upgrade hook
if [ "$1" = "post-upgrade" ]; then
    log_package_operation "post-upgrade" "$2" "$3"
fi

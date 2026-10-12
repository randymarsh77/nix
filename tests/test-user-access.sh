#!/bin/bash

# Test User Access - Validates expectations of ability to access the current user
# Expected to be run with sudo
# Usage: sudo ./test-user-access.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

test_assertion() {
    local description="$1"
    local condition="$2"
    
    if eval "$condition"; then
        log_success "$description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "$description"
        ((TESTS_FAILED++))
        return 1
    fi
}

log "Starting User Access Test"
log "=========================="

# Log current user context
log "User Context Information:"
log "Current effective user: $(whoami)"
log "Current effective UID: $(id -u)"
log "Current effective GID: $(id -g)"
log "SUDO_USER: ${SUDO_USER:-$(whoami)}"
log "SUDO_UID: ${SUDO_UID:-N/A}"
log "SUDO_GID: ${SUDO_GID:-N/A}"
log "USER: ${USER:-N/A}"
log "LOGNAME: ${LOGNAME:-N/A}"
log "HOME: ${HOME:-N/A}"

# Check if running with sudo
log ""
log "Sudo Environment Checks:"
if [[ -n "${SUDO_USER:-}" ]]; then
    log_success "Running with sudo (SUDO_USER=$SUDO_USER)"
    ORIGINAL_USER="$SUDO_USER"
    ORIGINAL_HOME=$(eval echo "~$SUDO_USER")
else
    log_warning "Not running with sudo - some tests may not be meaningful"
    ORIGINAL_USER="$(whoami)"
    ORIGINAL_HOME="$HOME"
fi

log "Original user: $ORIGINAL_USER"
log "Original user home: $ORIGINAL_HOME"

# Test 1: Validate sudo user exists
log ""
log "Test 1: Validating sudo user exists"
if [[ -n "${SUDO_USER:-}" ]]; then
    test_assertion "SUDO_USER variable is set" "[[ -n \"\${SUDO_USER:-}\" ]]"
    test_assertion "SUDO_USER exists in system" "id \"$SUDO_USER\" >/dev/null 2>&1"
    test_assertion "SUDO_UID matches user" "[[ \"\$(id -u \"$SUDO_USER\")\" == \"\${SUDO_UID:-}\" ]]"
else
    log_warning "Skipping sudo user validation (not running with sudo)"
fi

# Test 2: Validate current effective user is root
log ""
log "Test 2: Validating effective user permissions"
test_assertion "Current effective UID is 0 (root)" "[[ \$(id -u) -eq 0 ]]"
test_assertion "Can write to /etc (system directory)" "[[ -w /etc ]]"

# Test 3: Validate access to original user's home directory
log ""
log "Test 3: Validating access to original user resources"
if [[ -d "$ORIGINAL_HOME" ]]; then
    test_assertion "Can read original user's home directory" "[[ -r \"$ORIGINAL_HOME\" ]]"
    test_assertion "Original user's home directory exists" "[[ -d \"$ORIGINAL_HOME\" ]]"
    
    # Check if we can access common user directories
    for dir in ".config" ".local" "Desktop" "Documents"; do
        if [[ -d "$ORIGINAL_HOME/$dir" ]]; then
            test_assertion "Can access $ORIGINAL_HOME/$dir" "[[ -r \"$ORIGINAL_HOME/$dir\" ]]"
        fi
    done
else
    log_error "Original user's home directory does not exist: $ORIGINAL_HOME"
    ((TESTS_FAILED++))
fi

# Test 4: Validate ability to switch user context
log ""
log "Test 4: Validating user switching capabilities"
if command -v su >/dev/null 2>&1; then
    test_assertion "su command is available" "command -v su >/dev/null 2>&1"
    
    # Test switching to original user
    if [[ "$ORIGINAL_USER" != "root" ]]; then
        test_assertion "Can switch to original user context" "su - \"$ORIGINAL_USER\" -c 'whoami' >/dev/null 2>&1"
    fi
fi

# Test 5: Validate environment preservation
log ""
log "Test 5: Validating environment preservation"
test_assertion "PATH is preserved" "[[ -n \"\${PATH:-}\" ]]"
test_assertion "SHELL is set" "[[ -n \"\${SHELL:-}\" ]]"

if [[ -n "${SUDO_USER:-}" ]]; then
    # Get original user's shell
    ORIGINAL_SHELL=$(getent passwd "$SUDO_USER" | cut -d: -f7)
    log "Original user's shell: $ORIGINAL_SHELL"
    test_assertion "Original user has valid shell" "[[ -x \"$ORIGINAL_SHELL\" ]]"
fi

# Test 6: Validate file system permissions
log ""
log "Test 6: Validating file system permissions"
test_assertion "Can create temporary files" "touch /tmp/user-access-test-\$\$ && rm -f /tmp/user-access-test-\$\$"
test_assertion "Can read /proc filesystem" "[[ -r /proc/version ]]"
test_assertion "Can access system logs" "[[ -r /var/log ]] || [[ -r /Library/Logs ]]"

# Test 7: Validate user identification commands
log ""
log "Test 7: Validating user identification commands"
test_assertion "id command works" "id >/dev/null 2>&1"
test_assertion "whoami command works" "whoami >/dev/null 2>&1"
test_assertion "groups command works" "groups >/dev/null 2>&1"

# Additional logging of user groups and capabilities
log ""
log "Additional User Information:"
log "Current user groups: $(groups 2>/dev/null || echo 'N/A')"
if [[ -n "${SUDO_USER:-}" ]]; then
    log "Original user groups: $(groups \"$SUDO_USER\" 2>/dev/null || echo 'N/A')"
fi

# Test 8: Platform-specific tests
log ""
log "Test 8: Platform-specific validations"
if [[ "$(uname)" == "Darwin" ]]; then
    log "Running on macOS"
    test_assertion "Can access macOS system directories" "[[ -d /System ]]"
    test_assertion "Can read system profiler" "system_profiler SPSoftwareDataType >/dev/null 2>&1 || true"
elif [[ "$(uname)" == "Linux" ]]; then
    log "Running on Linux"
    test_assertion "Can access Linux system directories" "[[ -d /sys ]]"
    test_assertion "Can read system information" "[[ -r /proc/cpuinfo ]]"
fi

# Summary
log ""
log "Test Summary:"
log "============="
log "Tests passed: $TESTS_PASSED"
log "Tests failed: $TESTS_FAILED"
log "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    log_success "All tests passed! User access validation successful."
    exit 0
else
    log_error "Some tests failed. User access validation incomplete."
    exit 1
fi
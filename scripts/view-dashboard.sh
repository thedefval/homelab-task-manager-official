#!/usr/bin/env bash
#
# View the generated dashboards in default browser
# Usage: ./view-dashboard.sh [public]
#

set -euo pipefail

# Configuration
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"
DASHBOARD_DIR="$PROJECT_ROOT/dashboard"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Determine which dashboard to open
if [ "${1:-}" = "public" ]; then
    DASHBOARD="$DASHBOARD_DIR/public.html"
    DASHBOARD_TYPE="public"
else
    DASHBOARD="$DASHBOARD_DIR/index.html"
    DASHBOARD_TYPE="private"
fi

# Check if dashboard exists
if [ ! -f "$DASHBOARD" ]; then
    error_exit "Dashboard not found: $DASHBOARD\nRun: python3 scripts/generate-dashboard.py"
fi

success_msg "Opening $DASHBOARD_TYPE dashboard..."
echo "  File: dashboard/$(basename "$DASHBOARD")"

# Open dashboard in default browser
# Try different commands based on OS
if command -v xdg-open > /dev/null; then
    # Linux
    xdg-open "$DASHBOARD" 2>/dev/null
elif command -v open > /dev/null; then
    # macOS
    open "$DASHBOARD"
elif command -v start > /dev/null; then
    # Windows (Git Bash, WSL, etc.)
    start "$DASHBOARD"
else
    # Fallback: just show the path
    echo ""
    echo "Could not detect browser command. Open manually:"
    echo "  file://$DASHBOARD"
fi

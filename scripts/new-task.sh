#!/usr/bin/env bash
#
# Create a new task and automatically regenerate dashboards
# Usage: ./new-task.sh "Task Title" [category] [priority] [-p for private]
#

set -euo pipefail

# Configuration
TASKS_DIR="tasks"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help function
show_usage() {
    cat << EOF
Usage: $0 "Task Title" [category] [priority] [-p]

Arguments:
    Task Title    : Required. Title of the task (quoted if contains spaces)
    category      : Optional. Task category (default: general)
    priority      : Optional. urgent|high|medium|low (default: medium)
    -p            : Optional. Mark task as private (excluded from public dashboard)

Examples:
    $0 "Setup EVE-NG lab"
    $0 "Configure OSPF" networking high
    $0 "Sensitive task" security urgent -p
    $0 "Study for CCNP" learning medium

EOF
}

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Success message
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Warning message
warn_msg() {
    echo -e "${YELLOW}$1${NC}"
}

# Validate input
if [ $# -lt 1 ]; then
    error_exit "Task title is required"
    show_usage
    exit 1
fi

# Parse arguments
TASK_TITLE="$1"
CATEGORY="${2:-general}"
PRIORITY="${3:-medium}"
IS_PRIVATE=false

# Check for private flag
for arg in "$@"; do
    if [ "$arg" = "-p" ]; then
        IS_PRIVATE=true
    fi
done

# Validate priority
case "$PRIORITY" in
    urgent|high|medium|low)
        ;;
    *)
        warn_msg "Invalid priority '$PRIORITY'. Using 'medium'"
        PRIORITY="medium"
        ;;
esac

# Generate filename (sanitize title)
TIMESTAMP=$(date +%s)
FILENAME=$(echo "$TASK_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILENAME="${FILENAME:0:50}-${TIMESTAMP}.yaml"

# Create task file in backlog
TASK_FILE="$PROJECT_ROOT/$TASKS_DIR/backlog/$FILENAME"

# Ensure backlog directory exists
mkdir -p "$(dirname "$TASK_FILE")" || error_exit "Failed to create backlog directory"

# Get current UTC timestamp
CURRENT_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Create YAML file with security-conscious defaults
cat > "$TASK_FILE" << EOF
title: "$TASK_TITLE"
description: ""
category: $CATEGORY
priority: $PRIORITY
status: backlog
created: $CURRENT_TIME
updated: $CURRENT_TIME
tags: []
private: $IS_PRIVATE
EOF

# Verify file was created
if [ ! -f "$TASK_FILE" ]; then
    error_exit "Failed to create task file"
fi

success_msg "Task created: $FILENAME"
echo "  Title: $TASK_TITLE"
echo "  Category: $CATEGORY"
echo "  Priority: $PRIORITY"
echo "  Private: $IS_PRIVATE"
echo "  Location: $TASKS_DIR/backlog/$FILENAME"

# Sync tasks and auto-generate dashboards
echo ""
echo "Syncing tasks and regenerating dashboards..."
cd "$PROJECT_ROOT"

# Sync tasks to correct directories
if ! python3 "$SCRIPTS_DIR/sync-tasks.py"; then
    warn_msg "Task sync had warnings (task still created)"
fi

# Generate dashboards
if ! python3 "$SCRIPTS_DIR/generate-dashboard.py"; then
    error_exit "Dashboard generation failed"
fi

success_msg "Dashboards updated successfully"
echo ""
echo "Next steps:"
echo "  1. Edit the task: vim $TASKS_DIR/backlog/$FILENAME"
echo "  2. View dashboards: ./scripts/view-dashboard.sh"
echo "  3. Move task: ./scripts/move-task.sh $FILENAME todo"
echo "  4. Commit changes: git add . && git commit -m 'Add: $TASK_TITLE' && git push"

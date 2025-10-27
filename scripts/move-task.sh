#!/usr/bin/env bash
#
# Move a task between columns and automatically regenerate dashboards
# Usage: ./move-task.sh <task-filename> <destination-column>
#

set -euo pipefail

# Configuration
TASKS_DIR="tasks"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"
VALID_COLUMNS=("backlog" "todo" "in_progress" "stalled" "done")

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Help function
show_usage() {
    cat << EOF
Usage: $0 <task-filename> <destination-column>

Arguments:
    task-filename       : Filename of the task to move (e.g., setup-lab-1234567890.yaml)
    destination-column  : backlog | todo | in_progress | stalled | done

Examples:
    $0 setup-lab-1234567890.yaml todo
    $0 configure-ospf-1234567890.yaml in_progress
    $0 blocked-task-1234567890.yaml stalled
    $0 study-ccnp-1234567890.yaml done

EOF
}

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success_msg() {
    echo -e "${GREEN}$1${NC}"
}

warn_msg() {
    echo -e "${YELLOW}$1${NC}"
}

# Validate arguments
if [ $# -ne 2 ]; then
    show_usage
    error_exit "Exactly 2 arguments required"
fi

TASK_FILENAME="$1"
DEST_COLUMN="$2"

# Validate destination column
VALID=false
for col in "${VALID_COLUMNS[@]}"; do
    if [ "$DEST_COLUMN" = "$col" ]; then
        VALID=true
        break
    fi
done

if [ "$VALID" = false ]; then
    error_exit "Invalid destination column '$DEST_COLUMN'. Must be one of: ${VALID_COLUMNS[*]}"
fi

# Find the task file
TASK_FILE=""
for col in "${VALID_COLUMNS[@]}"; do
    POTENTIAL_FILE="$PROJECT_ROOT/$TASKS_DIR/$col/$TASK_FILENAME"
    if [ -f "$POTENTIAL_FILE" ]; then
        TASK_FILE="$POTENTIAL_FILE"
        SOURCE_COLUMN="$col"
        break
    fi
done

if [ -z "$TASK_FILE" ]; then
    error_exit "Task file '$TASK_FILENAME' not found in any column"
fi

# Check if already in destination
if [ "$SOURCE_COLUMN" = "$DEST_COLUMN" ]; then
    warn_msg "Task is already in '$DEST_COLUMN' column"
    exit 0
fi

# Ensure destination directory exists
DEST_DIR="$PROJECT_ROOT/$TASKS_DIR/$DEST_COLUMN"
mkdir -p "$DEST_DIR" || error_exit "Failed to create destination directory"

# Move the file
DEST_FILE="$DEST_DIR/$TASK_FILENAME"
if ! mv "$TASK_FILE" "$DEST_FILE"; then
    error_exit "Failed to move task file"
fi

# Update the status field in the YAML file
CURRENT_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Use sed to update status and updated fields
sed -i "s/^status:.*/status: $DEST_COLUMN/" "$DEST_FILE" || error_exit "Failed to update status field"
sed -i "s/^updated:.*/updated: $CURRENT_TIME/" "$DEST_FILE" || error_exit "Failed to update timestamp"

success_msg "Task moved: $SOURCE_COLUMN -> $DEST_COLUMN"
echo "  File: $TASK_FILENAME"
echo "  Location: $TASKS_DIR/$DEST_COLUMN/$TASK_FILENAME"

# Sync tasks and auto-generate dashboards
echo ""
echo "Syncing tasks and regenerating dashboards..."
cd "$PROJECT_ROOT"

# Sync tasks to correct directories
if ! python3 "$SCRIPTS_DIR/sync-tasks.py"; then
    warn_msg "Task sync had warnings (task still moved)"
fi

# Generate dashboards
if ! python3 "$SCRIPTS_DIR/generate-dashboard.py"; then
    error_exit "Dashboard generation failed"
fi

success_msg "Dashboards updated successfully"
echo ""
echo "Next steps:"
echo "  1. View dashboards: ./scripts/view-dashboard.sh"
echo "  2. Commit changes: git add . && git commit -m 'Move: $TASK_FILENAME to $DEST_COLUMN' && git push"

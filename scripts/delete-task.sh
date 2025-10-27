#!/usr/bin/env bash
#
# Delete a task and automatically regenerate dashboards
# Usage: ./delete-task.sh <task-filename>
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
Usage: $0 <task-filename>

Arguments:
    task-filename : Filename of the task to delete (e.g., setup-lab-1234567890.yaml)

Examples:
    $0 setup-lab-1234567890.yaml
    $0 configure-ospf-1234567890.yaml

Note: This permanently deletes the task file. Use with caution.

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
if [ $# -ne 1 ]; then
    show_usage
    error_exit "Task filename required"
fi

TASK_FILENAME="$1"

# Find the task file
TASK_FILE=""
SOURCE_COLUMN=""
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

# Extract task title for confirmation
TASK_TITLE=$(grep "^title:" "$TASK_FILE" | sed 's/^title: *"\?\(.*\)"\?$/\1/')

# Confirmation prompt
warn_msg "WARNING: You are about to permanently delete this task:"
echo "  File: $TASK_FILENAME"
echo "  Title: $TASK_TITLE"
echo "  Column: $SOURCE_COLUMN"
echo "  Location: $TASKS_DIR/$SOURCE_COLUMN/$TASK_FILENAME"
echo ""
read -p "Are you sure you want to delete this task? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deletion cancelled."
    exit 0
fi

# Delete the file
if ! rm "$TASK_FILE"; then
    error_exit "Failed to delete task file"
fi

success_msg "Task deleted: $TASK_FILENAME"

# Sync tasks and auto-generate dashboards
echo ""
echo "Syncing tasks and regenerating dashboards..."
cd "$PROJECT_ROOT"

# Sync tasks to correct directories
if ! python3 "$SCRIPTS_DIR/sync-tasks.py"; then
    warn_msg "Task sync had warnings"
fi

# Generate dashboards
if ! python3 "$SCRIPTS_DIR/generate-dashboard.py"; then
    error_exit "Dashboard generation failed"
fi

success_msg "Dashboards updated successfully"
echo ""
echo "Next steps:"
echo "  1. View dashboards: ./scripts/view-dashboard.sh"
echo "  2. Commit changes: git add . && git commit -m 'Delete: $TASK_TITLE' && git push"

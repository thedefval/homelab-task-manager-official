#!/usr/bin/env bash
#
# List all tasks with filtering options
# Usage: ./list-tasks.sh [column] [--private]
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
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Help function
show_usage() {
    cat << EOF
Usage: $0 [column] [--private]

Arguments:
    column      : Optional. Filter by column: backlog | todo | in_progress | stalled | done | all
    --private   : Optional. Show only private tasks

Examples:
    $0                  # List all tasks
    $0 todo             # List only todo tasks
    $0 in_progress      # List in-progress tasks
    $0 stalled          # List stalled tasks
    $0 done             # List completed tasks
    $0 --private        # List only private tasks
    $0 done --private   # List completed private tasks

EOF
}

# Parse arguments
FILTER_COLUMN="all"
SHOW_PRIVATE_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --private)
            SHOW_PRIVATE_ONLY=true
            ;;
        backlog|todo|in_progress|stalled|done|all)
            FILTER_COLUMN="$arg"
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
    esac
done

# Determine which columns to check
if [ "$FILTER_COLUMN" = "all" ]; then
    COLUMNS_TO_CHECK=("${VALID_COLUMNS[@]}")
else
    COLUMNS_TO_CHECK=("$FILTER_COLUMN")
fi

# Track totals
TOTAL_TASKS=0

# Iterate through columns
for column in "${COLUMNS_TO_CHECK[@]}"; do
    COLUMN_DIR="$PROJECT_ROOT/$TASKS_DIR/$column"
    
    if [ ! -d "$COLUMN_DIR" ]; then
        continue
    fi
    
    # Count tasks in this column
    TASK_COUNT=0
    for task_file in "$COLUMN_DIR"/*.yaml; do
        # Check if glob matched nothing
        if [ ! -f "$task_file" ]; then
            continue
        fi
        
        # Extract task info using grep/sed
        TITLE=$(grep "^title:" "$task_file" | sed 's/^title: *//; s/^"//; s/"$//')
        PRIORITY=$(grep "^priority:" "$task_file" | sed 's/^priority: *//')
        IS_PRIVATE=$(grep "^private:" "$task_file" | sed 's/^private: *//')
        CATEGORY=$(grep "^category:" "$task_file" | sed 's/^category: *//')
        
        # Filter by private flag
        if [ "$SHOW_PRIVATE_ONLY" = true ] && [ "$IS_PRIVATE" != "true" ]; then
            continue
        fi
        
        # Increment counters
        TASK_COUNT=$((TASK_COUNT + 1))
        TOTAL_TASKS=$((TOTAL_TASKS + 1))
        
        # Print task (first task in column = print header)
        if [ $TASK_COUNT -eq 1 ]; then
            echo ""
            # Column name with color
            case "$column" in
                backlog)    echo -e "${CYAN}=== BACKLOG ===${NC}" ;;
                todo)       echo -e "${BLUE}=== TO DO ===${NC}" ;;
                in_progress) echo -e "${YELLOW}=== IN PROGRESS ===${NC}" ;;
                stalled)    echo -e "${MAGENTA}=== STALLED ===${NC}" ;;
                done)       echo -e "${GREEN}=== DONE ===${NC}" ;;
            esac
        fi
        
        # Priority color
        PRIORITY_COLOR=$NC
        case "$PRIORITY" in
            urgent)  PRIORITY_COLOR=$RED ;;
            high)    PRIORITY_COLOR=$YELLOW ;;
            medium)  PRIORITY_COLOR=$BLUE ;;
            low)     PRIORITY_COLOR=$CYAN ;;
        esac
        
        # Task display
        FILENAME=$(basename "$task_file")
        PRIVATE_FLAG=""
        if [ "$IS_PRIVATE" = "true" ]; then
            PRIVATE_FLAG=" [PRIVATE]"
        fi
        
        echo -e "  ${PRIORITY_COLOR}[$PRIORITY]${NC} $TITLE$PRIVATE_FLAG"
        echo -e "    Category: $CATEGORY | File: $FILENAME"
    done
done

# Summary
echo ""
echo "---"
echo "Total tasks: $TOTAL_TASKS"

if [ $TOTAL_TASKS -eq 0 ]; then
    echo ""
    echo "No tasks found. Create one with: ./scripts/new-task.sh \"Task Title\""
fi

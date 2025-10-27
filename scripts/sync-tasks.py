#!/usr/bin/env python3
"""
Sync tasks to correct directories based on their YAML status field
Ensures tasks are in the right column directory matching their status
"""

import os
import sys
import yaml
import shutil
from pathlib import Path
from datetime import datetime

# Configuration
TASKS_DIR = Path("tasks")
VALID_COLUMNS = ["backlog", "todo", "in_progress", "stalled", "done"]

# Color codes
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
NC = '\033[0m'  # No Color


def log_info(msg):
    """Print info message"""
    print(f"{GREEN}{msg}{NC}")


def log_warn(msg):
    """Print warning message"""
    print(f"{YELLOW}{msg}{NC}")


def log_error(msg):
    """Print error message"""
    print(f"{RED}{msg}{NC}", file=sys.stderr)


def sync_tasks():
    """Sync all tasks to correct directories based on status field"""
    moved_count = 0
    error_count = 0
    
    # Iterate through all columns
    for current_column in VALID_COLUMNS:
        column_dir = TASKS_DIR / current_column
        
        if not column_dir.exists():
            continue
        
        for task_file in column_dir.glob("*.yaml"):
            try:
                # Read task
                with open(task_file, 'r', encoding='utf-8') as f:
                    task_data = yaml.safe_load(f)
                
                if not task_data:
                    continue
                
                # Get status from YAML
                yaml_status = task_data.get('status', '').lower()
                
                # Validate status
                if yaml_status not in VALID_COLUMNS:
                    log_warn(f"Invalid status '{yaml_status}' in {task_file.name}, skipping")
                    error_count += 1
                    continue
                
                # Check if task is in wrong directory
                if yaml_status != current_column:
                    # Move task to correct directory
                    dest_dir = TASKS_DIR / yaml_status
                    dest_dir.mkdir(parents=True, exist_ok=True)
                    dest_file = dest_dir / task_file.name
                    
                    # Update timestamp
                    task_data['updated'] = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
                    
                    # Write updated task to new location
                    with open(dest_file, 'w', encoding='utf-8') as f:
                        yaml.dump(task_data, f, default_flow_style=False, allow_unicode=True)
                    
                    # Remove old file
                    task_file.unlink()
                    
                    title = task_data.get('title', 'Untitled')
                    print(f"  Moved: {title}")
                    print(f"    From: tasks/{current_column}/{task_file.name}")
                    print(f"    To:   tasks/{yaml_status}/{task_file.name}")
                    moved_count += 1
                    
            except yaml.YAMLError as e:
                log_error(f"YAML error in {task_file}: {str(e)}")
                error_count += 1
            except Exception as e:
                log_error(f"Error processing {task_file}: {str(e)}")
                error_count += 1
    
    return moved_count, error_count


def main():
    """Main execution"""
    try:
        print("Syncing tasks to correct directories...")
        print("")
        
        moved, errors = sync_tasks()
        
        print("")
        if moved > 0:
            log_info(f"Synced {moved} task(s) to correct directories")
        else:
            log_info("All tasks are already in correct directories")
        
        if errors > 0:
            log_warn(f"Encountered {errors} error(s)")
            return 1
        
        return 0
        
    except Exception as e:
        log_error(f"Fatal error: {str(e)}")
        return 1


if __name__ == "__main__":
    sys.exit(main())

# Quick Start Guide

Get up and running with Homelab Task Manager in 5 minutes.

## Installation

### 1. Install Dependencies

**On CachyOS/Arch Linux:**
```bash
sudo pacman -S python-yaml
```

**On Ubuntu/Debian:**
```bash
sudo apt install python3-yaml
```

**On macOS:**
```bash
pip3 install pyyaml
```

### 2. Make Scripts Executable

```bash
chmod +x scripts/*.sh scripts/*.py
```

### 3. Initialize Git Repository

```bash
./scripts/init-repo.sh thedefval

# This will:
# - Initialize git
# - Install pre-commit hook for auto-dashboard generation
# - Create initial commit
# - Set up GitHub remote
```

## First Steps

### Create Your First Task

```bash
./scripts/new-task.sh "My First Task" general medium
```

This creates a YAML file, syncs tasks, and generates dashboards automatically.

### View Your Dashboard

```bash
./scripts/view-dashboard.sh
```

Opens `dashboard/index.html` in your browser.

### List Tasks

```bash
./scripts/list-tasks.sh
```

Shows all tasks in your terminal.

## Basic Workflow

### 1. Create Tasks

```bash
./scripts/new-task.sh "Task Title" category priority
```

Examples:
```bash
./scripts/new-task.sh "Setup EVE-NG" lab-infrastructure high
./scripts/new-task.sh "Study CCNP Ch3" certification medium
./scripts/new-task.sh "Secret Project" work urgent -p  # Private task
```

### 2. Move Tasks Forward

```bash
# Find the task filename
ls tasks/backlog/

# Move to "To Do"
./scripts/move-task.sh my-task-1234567890.yaml todo

# Move to "In Progress" when starting
./scripts/move-task.sh my-task-1234567890.yaml in_progress

# Move to "Stalled" if blocked
./scripts/move-task.sh my-task-1234567890.yaml stalled

# Move to "Done" when complete
./scripts/move-task.sh my-task-1234567890.yaml done
```

### 3. Edit Tasks

```bash
vim tasks/todo/my-task-1234567890.yaml

# Add description, tags, etc.
# Save and exit
```

### 4. Commit and Push

```bash
git add .
git commit -m "Daily progress"

# Pre-commit hook automatically:
# - Syncs tasks to correct directories
# - Regenerates dashboards
# - Adds them to the commit

git push
```

## Key Features

### Automatic Task Syncing

Tasks automatically move to correct directories based on their `status` field:

```yaml
# Edit the status in any task YAML file
status: in_progress

# On commit, task automatically moves to tasks/in_progress/
```

### Automatic Dashboard Generation

Dashboards regenerate automatically on every commit via git pre-commit hook.

### Stalled Status

Use `stalled` for blocked or waiting tasks:

```bash
./scripts/move-task.sh waiting-for-equipment.yaml stalled
```

### Private Tasks

Keep sensitive tasks out of public dashboard:

```bash
./scripts/new-task.sh "Confidential" work high -p
```

## Common Commands Reference

```bash
# Create task
./scripts/new-task.sh "Title" [category] [priority] [-p]

# Move task
./scripts/move-task.sh <filename> <backlog|todo|in_progress|stalled|done>

# List tasks
./scripts/list-tasks.sh [column] [--private]

# Delete task
./scripts/delete-task.sh <filename>

# View dashboard
./scripts/view-dashboard.sh [public]

# Sync tasks manually (usually automatic)
python3 scripts/sync-tasks.py

# Generate dashboards manually (usually automatic)
python3 scripts/generate-dashboard.py
```

## Priority Levels

- **urgent**: Critical, do immediately
- **high**: Important, do soon
- **medium**: Normal priority (default)
- **low**: Nice to have

## Task Columns

- **backlog**: Future tasks, not ready yet
- **todo**: Ready to start, prioritized
- **in_progress**: Currently working on
- **stalled**: Blocked or waiting
- **done**: Completed

## Tips

1. **Use categories** to group related tasks
2. **Add tags** for cross-cutting concerns
3. **Mark work tasks private** to exclude from public dashboard
4. **Edit YAML files directly** for detailed descriptions
5. **Let the hooks work** - they auto-update everything on commit

## Next Steps

1. Read the full [README.md](../README.md) for detailed documentation
2. Customize categories for your workflow
3. Build your task backlog
4. Push to GitHub
5. Share your public dashboard

## Need Help?

- Check the full README.md
- Look at example tasks in `tasks/` directories
- All scripts accept `-h` or `--help` (where implemented)

Happy tasking!

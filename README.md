# Homelab Task Manager

A local-first, Git-based task management system designed for homelab enthusiasts, network engineers, and system architects. Manage tasks with YAML files, generate beautiful HTML dashboards automatically, and sync everything to GitHub for backup.

## Features

- **Local-First Workflow**: All tasks stored as YAML files, no external dependencies
- **Automatic Dashboard Generation**: HTML dashboards regenerate on git commit via pre-commit hook
- **Automatic Task Syncing**: Tasks automatically move to correct directories based on YAML status field
- **Dual Dashboards**: Private dashboard (all tasks) and public dashboard (excludes private tasks)
- **Git-Based Backup**: Dashboards sync to GitHub with normal push/pull workflow
- **Stalled Task Tracking**: Dedicated column for blocked or waiting tasks
- **Security-Focused**: HTML escaping, safe YAML loading, comprehensive error handling
- **Vim-Friendly**: Plain text YAML files for easy editing
- **Cross-Platform**: Works on Linux, macOS, and Windows (Git Bash/WSL)

## Prerequisites

- Git
- Python 3.7+
- PyYAML library (`pip install pyyaml` or `pacman -S python-yaml` on Arch)
- Bash shell (works in Fish shell too)

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/thedefval/homelab-task-manager-official.git
cd homelab-task-manager-official

# Make scripts executable
chmod +x scripts/*.sh scripts/*.py

# Install Python dependencies
# On Arch/CachyOS:
sudo pacman -S python-yaml

# On other systems:
pip install pyyaml --break-system-packages
```

### 2. Initialize Git and Install Hooks

```bash
# Initialize git repository and install pre-commit hook
./scripts/init-repo.sh yourusername

# This will:
# - Initialize git (if needed)
# - Install pre-commit hook for auto-dashboard generation
# - Create initial commit
# - Set up GitHub remote
```

### 3. Create Your First Task

```bash
# Create a new task (automatically goes to backlog)
./scripts/new-task.sh "Setup EVE-NG Lab" networking high

# The script will:
# 1. Create the task YAML file in tasks/backlog/
# 2. Sync tasks to correct directories
# 3. Auto-generate both dashboards
# 4. Show you next steps
```

### 4. View Your Dashboard

```bash
# Open private dashboard (shows all tasks)
./scripts/view-dashboard.sh

# Open public dashboard (excludes private tasks)
./scripts/view-dashboard.sh public
```

### 5. Manage Tasks

```bash
# List all tasks
./scripts/list-tasks.sh

# Move a task to different column
./scripts/move-task.sh setup-eve-ng-lab-1234567890.yaml todo
./scripts/move-task.sh setup-eve-ng-lab-1234567890.yaml in_progress
./scripts/move-task.sh setup-eve-ng-lab-1234567890.yaml stalled
./scripts/move-task.sh setup-eve-ng-lab-1234567890.yaml done

# Delete a task
./scripts/delete-task.sh setup-eve-ng-lab-1234567890.yaml
```

### 6. Edit Tasks Directly

Tasks are plain YAML files. Edit them with your favorite editor:

```bash
# Edit a task
vim tasks/backlog/setup-eve-ng-lab-1234567890.yaml

# After editing, commit (dashboards auto-regenerate via hook)
git add .
git commit -m "Update: task details"
git push
```

## Project Structure

```
homelab-task-manager/
├── tasks/                      # Task storage (YAML files)
│   ├── backlog/               # Future tasks
│   ├── todo/                  # Ready to start
│   ├── in_progress/           # Currently working on
│   ├── stalled/               # Blocked or waiting
│   └── done/                  # Completed tasks
├── scripts/                    # Helper scripts
│   ├── new-task.sh            # Create new tasks
│   ├── move-task.sh           # Move tasks between columns
│   ├── list-tasks.sh          # List tasks in terminal
│   ├── delete-task.sh         # Delete tasks
│   ├── view-dashboard.sh      # Open dashboards in browser
│   ├── sync-tasks.py          # Sync tasks based on YAML status
│   ├── generate-dashboard.py  # Dashboard generator
│   ├── install-hooks.sh       # Install git hooks
│   └── init-repo.sh           # Initialize git repository
├── dashboard/                  # Generated dashboards (tracked in Git)
│   ├── index.html             # Private dashboard (all tasks)
│   └── public.html            # Public dashboard (no private tasks)
├── .git/hooks/
│   └── pre-commit             # Auto-regenerate dashboards on commit
├── docs/                       # Documentation
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

## Task File Format

Tasks are stored as YAML files with this structure:

```yaml
title: "Setup EVE-NG Lab"
description: "Install and configure EVE-NG for network simulation"
category: networking
priority: high
status: backlog
created: 2025-10-26 10:00:00 UTC
updated: 2025-10-26 10:00:00 UTC
tags:
  - virtualization
  - lab-setup
private: false
```

### Field Descriptions

- **title**: Task title (required, auto-escaped for security)
- **description**: Detailed description (optional)
- **category**: Task category for grouping (default: general)
- **priority**: urgent | high | medium | low (default: medium)
- **status**: backlog | todo | in_progress | stalled | done (auto-synced to directory)
- **created**: UTC timestamp of creation (auto-generated)
- **updated**: UTC timestamp of last modification (auto-updated)
- **tags**: List of tags for categorization (optional)
- **private**: true | false - excludes from public dashboard (default: false)

## Key Features Explained

### Automatic Task Syncing

Tasks automatically move to the correct directory based on their `status` field in the YAML file.

**How it works:**
1. Edit a task's `status` field in the YAML file
2. Run `python3 scripts/sync-tasks.py` (or it runs automatically on commit)
3. Task file moves to the matching directory
4. Dashboards regenerate

**Example:**
```yaml
# Edit the status in tasks/todo/my-task.yaml
status: in_progress

# Commit the change
git add .
git commit -m "Started working on task"

# Pre-commit hook automatically:
# - Syncs the task to tasks/in_progress/
# - Regenerates dashboards
# - Adds changes to the commit
```

### Automatic Dashboard Generation on Commit

The git pre-commit hook ensures dashboards are always up-to-date.

**What happens on `git commit`:**
1. Tasks sync to correct directories based on status
2. Dashboards regenerate with latest data
3. Updated dashboards are added to the commit
4. Commit proceeds with updated files

**To install the hook:**
```bash
./scripts/install-hooks.sh
```

### Stalled Task Tracking

The `stalled` status helps track tasks that are blocked or waiting.

**Use cases:**
- Waiting for equipment delivery
- Blocked by dependencies
- Waiting for approvals
- Paused indefinitely

**Example:**
```bash
# Move a blocked task to stalled
./scripts/move-task.sh waiting-for-equipment.yaml stalled
```

The stalled column is highlighted in the dashboard for visibility.

## Usage Guide

### Creating Tasks

**Basic task:**
```bash
./scripts/new-task.sh "Task Title"
```

**With category and priority:**
```bash
./scripts/new-task.sh "Configure OSPF" networking high
```

**Private task (excluded from public dashboard):**
```bash
./scripts/new-task.sh "Sensitive server setup" security urgent -p
```

### Moving Tasks

Move tasks through your workflow:

```bash
# Move to "To Do" when ready to start
./scripts/move-task.sh taskfile.yaml todo

# Move to "In Progress" when working
./scripts/move-task.sh taskfile.yaml in_progress

# Move to "Stalled" if blocked
./scripts/move-task.sh taskfile.yaml stalled

# Move back to "In Progress" when unblocked
./scripts/move-task.sh taskfile.yaml in_progress

# Move to "Done" when complete
./scripts/move-task.sh taskfile.yaml done
```

### Listing Tasks

```bash
# List all tasks
./scripts/list-tasks.sh

# List tasks in specific column
./scripts/list-tasks.sh todo
./scripts/list-tasks.sh in_progress
./scripts/list-tasks.sh stalled

# List only private tasks
./scripts/list-tasks.sh --private

# Combine filters
./scripts/list-tasks.sh done --private
```

### Manual Editing

Edit task files directly for detailed changes:

```bash
# Edit the task
vim tasks/todo/configure-ospf-1234567890.yaml

# Commit (dashboards auto-regenerate via hook)
git add .
git commit -m "Update task details"
```

### Viewing Dashboards

```bash
# Open private dashboard (all tasks)
./scripts/view-dashboard.sh

# Open public dashboard (no private tasks)
./scripts/view-dashboard.sh public
```

Dashboards are also accessible directly:
- Private: `dashboard/index.html`
- Public: `dashboard/public.html`

## Security Features

### Input Validation & Sanitization

- All user inputs are HTML-escaped to prevent XSS attacks
- YAML files use `safe_load()` to prevent code injection
- Priority and status values are validated against allowed lists
- Comprehensive error handling throughout

### Private Tasks

Mark sensitive tasks as private to exclude them from public dashboards:

```bash
# Create private task
./scripts/new-task.sh "Sensitive task" security high -p

# Or edit YAML directly
private: true
```

Private tasks:
- Appear in `dashboard/index.html` (private dashboard)
- Excluded from `dashboard/public.html` (public dashboard)
- Stored in Git (use private repository for sensitive data)

### Compliance Considerations

For network engineers and system architects handling sensitive data:

- **Use Private Repositories**: Always use private GitHub repos for work-related tasks
- **No Credentials**: Never put passwords, API keys, or credentials in task descriptions
- **Data Classification**: Use the `private` flag for tasks containing confidential information
- **Access Control**: Manage GitHub repository access carefully
- **Audit Trail**: Git history provides complete audit trail of task changes

## Git Workflow

### Normal Workflow

```bash
# Make changes (create, edit, move, delete tasks)
./scripts/new-task.sh "New Task"

# Commit changes
git add .
git commit -m "Add: New Task"

# Pre-commit hook automatically:
# - Syncs tasks to correct directories
# - Regenerates dashboards
# - Adds updated files to commit

# Push to GitHub
git push
```

### Pulling Changes

```bash
# Pull from remote
git pull

# Dashboards are already up-to-date from remote
# No need to regenerate manually
```

### Sharing Public Dashboard

The public dashboard (`dashboard/public.html`) can be safely shared as it excludes all private tasks. You can:

1. **GitHub Pages**: Enable GitHub Pages to host `public.html`
2. **Direct Link**: Share the raw GitHub URL to `public.html`
3. **Export**: Copy `public.html` to share via email or file transfer

## Customization

### Adding Custom Categories

Categories are freeform text. Use any category that makes sense for your workflow:

```bash
./scripts/new-task.sh "Task" networking
./scripts/new-task.sh "Task" homelab
./scripts/new-task.sh "Task" certification
./scripts/new-task.sh "Task" learning
```

### Adding Custom Tags

Edit task YAML files to add tags:

```yaml
tags:
  - cisco
  - ccnp
  - routing
  - ospf
```

### Dashboard Customization

To customize dashboard appearance, edit `scripts/generate-dashboard.py`:

- Modify CSS in the `generate_html()` function
- Change color scheme by updating color codes
- Add new statistics or visualizations

## Troubleshooting

### Dashboards Not Updating After Commit

If dashboards don't update automatically:

```bash
# Check if pre-commit hook is installed
ls -la .git/hooks/pre-commit

# Reinstall hook if missing
./scripts/install-hooks.sh
```

### Tasks in Wrong Directories

If tasks are in directories that don't match their status:

```bash
# Manually sync tasks
python3 scripts/sync-tasks.py

# Regenerate dashboards
python3 scripts/generate-dashboard.py
```

### Script Permission Errors

If scripts won't execute:

```bash
# Make executable
chmod +x scripts/*.sh scripts/*.py
```

### Python Module Not Found

If you get "ModuleNotFoundError: No module named 'yaml'":

```bash
# Arch/CachyOS:
sudo pacman -S python-yaml

# Other systems:
pip install pyyaml --break-system-packages
```

## Architecture Decisions

### Why Auto-Sync Tasks?

- **Single Source of Truth**: YAML status field determines task location
- **Flexibility**: Edit status in file or use scripts
- **Consistency**: Tasks always in correct directory
- **No Manual Moving**: System handles directory management

### Why Auto-Generate on Commit?

- **Always Up-to-Date**: Dashboards never stale
- **No Extra Steps**: Automatic on commit
- **Version Control**: Dashboards tracked with tasks
- **Backup**: Dashboards preserved in Git history

### Why Stalled Column?

- **Visibility**: Blocked tasks don't hide in backlog
- **Tracking**: Know what's waiting
- **Planning**: Identify dependencies
- **Workflow**: Distinguish blocked from backlog

## License

MIT License - Feel free to use and modify for your needs.

## Author

Created by thedefval - Network Engineer & System Architect

## Feedback

Issues, suggestions, and improvements welcome via GitHub Issues.

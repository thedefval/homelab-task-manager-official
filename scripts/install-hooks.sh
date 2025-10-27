#!/usr/bin/env bash
#
# Install git hooks for automatic dashboard generation
# Usage: ./install-hooks.sh
#

set -euo pipefail

# Configuration
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success_msg() {
    echo -e "${GREEN}$1${NC}"
}

warn_msg() {
    echo -e "${YELLOW}$1${NC}"
}

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    error_exit "Not a git repository. Run 'git init' first."
fi

# Ensure hooks directory exists
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/usr/bin/env bash
#
# Git pre-commit hook
# Automatically syncs tasks and regenerates dashboards before each commit
#

# Get the root directory of the git repository
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Pre-commit hook: Syncing tasks and regenerating dashboards...${NC}"

# Sync tasks to correct directories based on YAML status
if python3 scripts/sync-tasks.py; then
    echo -e "${GREEN}Task sync complete${NC}"
else
    echo -e "${YELLOW}Warning: Task sync had issues, but continuing...${NC}"
fi

# Regenerate dashboards
if python3 scripts/generate-dashboard.py; then
    echo -e "${GREEN}Dashboards regenerated${NC}"
    
    # Add the updated dashboards to the commit
    git add dashboard/index.html dashboard/public.html 2>/dev/null || true
    
    # Add any tasks that were moved during sync
    git add tasks/ 2>/dev/null || true
    
    echo -e "${GREEN}Updated dashboards added to commit${NC}"
else
    echo -e "${RED}Error: Dashboard generation failed${NC}"
    echo -e "${RED}Commit aborted. Fix errors and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Pre-commit hook complete${NC}"
echo ""
EOF

# Make hook executable
chmod +x "$PRE_COMMIT_HOOK"

success_msg "Git pre-commit hook installed successfully!"
echo ""
echo "The hook will automatically:"
echo "  1. Sync tasks to correct directories based on YAML status"
echo "  2. Regenerate dashboards before each commit"
echo "  3. Add updated dashboards to the commit"
echo ""
echo "This ensures your dashboards are always up-to-date in Git!"

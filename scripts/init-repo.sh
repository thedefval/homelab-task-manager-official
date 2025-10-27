#!/usr/bin/env bash
#
# Initialize Git repository and set up remote
# Usage: ./init-repo.sh <your-github-username> [repo-name]
#

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Help
show_usage() {
    cat << EOF
Usage: $0 <github-username> [repo-name]

Arguments:
    github-username : Your GitHub username
    repo-name       : Repository name (default: homelab-task-manager)

Example:
    $0 thedefval
    $0 thedefval my-tasks

This script will:
1. Initialize a Git repository
2. Add all files
3. Create initial commit
4. Install git pre-commit hook for auto-dashboard generation
5. Set up GitHub remote
6. Show instructions for creating GitHub repo and pushing

EOF
}

if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

GITHUB_USER="$1"
REPO_NAME="${2:-homelab-task-manager}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

cd "$PROJECT_ROOT"

echo -e "${GREEN}Initializing Git repository...${NC}"

# Initialize git if not already initialized
if [ ! -d ".git" ]; then
    git init
    echo "Repository initialized"
else
    echo "Repository already initialized"
fi

# Install git hooks
echo -e "${GREEN}Installing git pre-commit hook...${NC}"
"$SCRIPTS_DIR/install-hooks.sh"

# Add all files
echo -e "${GREEN}Adding files...${NC}"
git add .

# Create initial commit
echo -e "${GREEN}Creating initial commit...${NC}"
if git commit -m "Initial commit: Homelab Task Manager setup"; then
    echo "Initial commit created"
else
    echo "Commit already exists or no changes to commit"
fi

# Set up remote
REMOTE_URL="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
echo -e "${GREEN}Setting up remote...${NC}"

if git remote | grep -q "^origin$"; then
    echo "Remote 'origin' already exists. Updating URL..."
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi

echo -e "${GREEN}Remote configured: $REMOTE_URL${NC}"

# Instructions
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "1. Create a new GitHub repository:"
echo "   - Go to: https://github.com/new"
echo "   - Repository name: $REPO_NAME"
echo "   - Make it PRIVATE if handling sensitive data"
echo "   - Do NOT initialize with README, .gitignore, or license"
echo ""
echo "2. Push your code:"
echo "   git push -u origin main"
echo ""
echo "   (If that fails with 'main' not found, try:)"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Set up SSH keys if needed:"
echo "   https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
echo ""
echo -e "${GREEN}Repository initialized successfully!${NC}"
echo ""
echo "Note: The pre-commit hook will automatically regenerate"
echo "dashboards before each commit, keeping them always up-to-date!"

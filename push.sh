#!/bin/bash

# Dotfiles Push Script
# Commit and push changes to the repository

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
Usage: $0 [commit-message] [OPTIONS]

Commit and push dotfiles changes to the repository.

Arguments:
    commit-message    Commit message (optional, will prompt if not provided)

Options:
    --dry-run        Show what would be committed without actually doing it
    --help          Show this help message

Examples:
    $0 "Updated zsh configuration"
    $0 --dry-run
    $0              (will prompt for commit message)
EOF
}

# Parse arguments
COMMIT_MESSAGE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$COMMIT_MESSAGE" ]]; then
                COMMIT_MESSAGE="$1"
            else
                log_error "Multiple commit messages specified"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

cd "$DOTFILES_DIR"

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
    log_error "Not in a git repository. Please initialize git first:"
    log_info "  cd $DOTFILES_DIR"
    log_info "  git init"
    log_info "  git remote add origin <your-repo-url>"
    exit 1
fi

# Check if there are any changes
if [[ -z "$(git status --porcelain)" ]]; then
    log_info "No changes to commit"
    exit 0
fi

# Show status
log_info "Current status:"
git status --short

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be committed"
    log_info "Changes that would be committed:"
    git diff --cached --name-status 2>/dev/null || git diff --name-status
    exit 0
fi

# Get commit message if not provided
if [[ -z "$COMMIT_MESSAGE" ]]; then
    echo
    log_info "Enter commit message:"
    read -r COMMIT_MESSAGE
    
    if [[ -z "$COMMIT_MESSAGE" ]]; then
        log_error "Commit message cannot be empty"
        exit 1
    fi
fi

# Add all changes
log_info "Adding changes..."
git add .

# Show what will be committed
log_info "Changes to be committed:"
git diff --cached --name-status

# Confirm commit
echo
read -p "Commit these changes with message '$COMMIT_MESSAGE'? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Commit cancelled"
    # Unstage the changes
    git reset HEAD .
    exit 0
fi

# Commit changes
log_info "Committing changes..."
if git commit -m "$COMMIT_MESSAGE"; then
    log_success "Changes committed successfully"
else
    log_error "Failed to commit changes"
    exit 1
fi

# Push changes
log_info "Pushing changes to remote repository..."
if git push; then
    log_success "Changes pushed successfully"
else
    log_error "Failed to push changes"
    log_info "You may need to set up the remote repository first:"
    log_info "  git remote add origin <your-repo-url>"
    log_info "  git push -u origin main"
    exit 1
fi

log_success "Dotfiles changes successfully pushed!"
log_info "Latest commit: $(git log -1 --oneline)"

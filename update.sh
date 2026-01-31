#!/bin/bash

# Dotfiles Update Script
# Pull latest changes from the repository and reinstall

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
Usage: $0 [OPTIONS]

Update dotfiles from the repository.

Options:
    --no-install      Don't reinstall dotfiles after pulling updates
    --help           Show this help message

Examples:
    $0                Update and reinstall dotfiles
    $0 --no-install   Just pull updates without reinstalling
EOF
}

# Parse arguments
REINSTALL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-install)
            REINSTALL=false
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
            log_error "Unexpected argument: $1"
            show_help
            exit 1
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
    log_info "  git pull origin main"
    exit 1
fi

# Check for uncommitted changes
if [[ -n "$(git status --porcelain)" ]]; then
    log_warning "You have uncommitted changes:"
    git status --short
    echo
    read -p "Do you want to stash these changes and continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled. Commit or stash your changes first."
        exit 0
    fi
    
    git stash push -m "Auto-stash before update on $(date)"
    log_success "Changes stashed"
    STASHED=true
else
    STASHED=false
fi

# Pull latest changes
log_info "Pulling latest changes..."
if git pull; then
    log_success "Successfully pulled latest changes"
else
    log_error "Failed to pull changes"
    
    if [[ "$STASHED" == true ]]; then
        log_info "Restoring stashed changes..."
        git stash pop
    fi
    exit 1
fi

# Show what changed
log_info "Recent changes:"
git log --oneline -10 --color=always

# Reinstall if requested
if [[ "$REINSTALL" == true ]]; then
    echo
    log_info "Reinstalling dotfiles..."
    if [[ -x "$DOTFILES_DIR/install.sh" ]]; then
        "$DOTFILES_DIR/install.sh"
    else
        log_error "install.sh not found or not executable"
        exit 1
    fi
fi

# Restore stashed changes if any
if [[ "$STASHED" == true ]]; then
    echo
    log_info "Restoring your stashed changes..."
    if git stash pop; then
        log_success "Stashed changes restored"
    else
        log_warning "Could not restore stashed changes automatically"
        log_info "Your changes are still in the stash. Use 'git stash pop' manually."
    fi
fi

log_success "Dotfiles update completed!"
log_info "If you updated shell configurations, run: source ~/.zshrc"

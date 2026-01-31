#!/bin/bash

# Remote Dotfiles Sync Script
# This script syncs dotfiles to remote machines via SSH

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

# Default files to sync
DEFAULT_FILES="zshrc,aliases.zsh,gitconfig,vimrc"

show_help() {
    cat << EOF
Usage: $0 [user@]hostname [OPTIONS]

Sync dotfiles to a remote machine via SSH.

Arguments:
    [user@]hostname    Remote host to sync to (e.g., user@server.com)

Options:
    --files=LIST       Comma-separated list of files to sync (default: $DEFAULT_FILES)
    --dry-run         Show what would be synced without actually doing it
    --help           Show this help message

Examples:
    $0 user@remote-server.com
    $0 user@server.com --files="zshrc,aliases.zsh"
    $0 user@server.com --dry-run

Available files to sync:
    zshrc           Shell configuration
    aliases.zsh     Shell aliases
    gitconfig       Git configuration
    vimrc           Vim configuration
    ssh_config      SSH configuration template
EOF
}

# Parse arguments
REMOTE_HOST=""
FILES_TO_SYNC="$DEFAULT_FILES"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --files=*)
            FILES_TO_SYNC="${1#*=}"
            shift
            ;;
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
            if [[ -z "$REMOTE_HOST" ]]; then
                REMOTE_HOST="$1"
            else
                log_error "Multiple hostnames specified"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$REMOTE_HOST" ]]; then
    log_error "Remote host not specified"
    show_help
    exit 1
fi

# Test SSH connection
log_info "Testing SSH connection to $REMOTE_HOST..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_HOST" echo "Connection successful" > /dev/null 2>&1; then
    log_error "Cannot connect to $REMOTE_HOST. Please check your SSH configuration."
    exit 1
fi
log_success "SSH connection to $REMOTE_HOST successful"

# Convert comma-separated list to array
IFS=',' read -ra FILES_ARRAY <<< "$FILES_TO_SYNC"

# Create remote installation script
REMOTE_SCRIPT=$(cat << 'SCRIPT_EOF'
#!/bin/bash
set -e

BACKUP_DIR="$HOME/.dotfiles_sync_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Function to backup and install file
install_file() {
    local temp_file="$1"
    local target_file="$2"
    local target_dir="$(dirname "$target_file")"
    
    # Create directory if needed
    mkdir -p "$target_dir"
    
    # Backup existing file
    if [[ -e "$target_file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$target_file" "$BACKUP_DIR/"
        log_warning "Backed up $target_file"
    fi
    
    # Install new file
    mv "$temp_file" "$target_file"
    log_success "Installed $target_file"
}

# Process each uploaded file
while read -r line; do
    [[ -z "$line" ]] && continue
    temp_file="$(echo "$line" | cut -d: -f1)"
    target_file="$(echo "$line" | cut -d: -f2-)"
    install_file "$temp_file" "$target_file"
done

if [[ -d "$BACKUP_DIR" ]]; then
    log_info "Backup created at: $BACKUP_DIR"
fi

# Install Oh My Zsh if needed and zshrc was synced
if [[ -f "$HOME/.zshrc" ]] && [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Create Oh My Zsh custom directory for aliases
if [[ -f "/tmp/aliases.zsh.sync" ]]; then
    mkdir -p "$HOME/.oh-my-zsh/custom"
    if [[ -e "$HOME/.oh-my-zsh/custom/aliases.zsh" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$HOME/.oh-my-zsh/custom/aliases.zsh" "$BACKUP_DIR/"
        log_warning "Backed up existing aliases.zsh"
    fi
    mv "/tmp/aliases.zsh.sync" "$HOME/.oh-my-zsh/custom/aliases.zsh"
    log_success "Installed aliases.zsh"
fi

log_success "Remote dotfiles sync completed!"
log_info "Run 'source ~/.zshrc' to reload shell configuration"
SCRIPT_EOF
)

log_info "Syncing dotfiles to $REMOTE_HOST"
log_info "Files to sync: $FILES_TO_SYNC"

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No files will be transferred"
fi

# Prepare file mappings
file_mappings=""

for file in "${FILES_ARRAY[@]}"; do
    file=$(echo "$file" | xargs)  # trim whitespace
    source_file="$DOTFILES_DIR/configs/$file"
    
    if [[ ! -f "$source_file" ]]; then
        log_warning "File not found: $source_file (skipping)"
        continue
    fi
    
    # Determine target path
    case "$file" in
        "zshrc")
            target_path="\$HOME/.zshrc"
            temp_file="/tmp/zshrc.sync"
            ;;
        "aliases.zsh")
            # Special handling for aliases - will be processed separately
            continue
            ;;
        "gitconfig")
            target_path="\$HOME/.gitconfig"
            temp_file="/tmp/gitconfig.sync"
            ;;
        "vimrc")
            target_path="\$HOME/.vimrc"
            temp_file="/tmp/vimrc.sync"
            ;;
        "ssh_config")
            target_path="\$HOME/.ssh/config"
            temp_file="/tmp/ssh_config.sync"
            ;;
        *)
            log_warning "Unknown file type: $file (skipping)"
            continue
            ;;
    esac
    
    file_mappings="$file_mappings$temp_file:$target_path\n"
    
    if [[ "$DRY_RUN" == false ]]; then
        log_info "Uploading $file..."
        scp "$source_file" "$REMOTE_HOST:$temp_file"
    else
        log_info "Would upload: $source_file -> $REMOTE_HOST:$temp_file"
    fi
done

# Handle aliases separately (special case)
if [[ " ${FILES_ARRAY[*]} " =~ " aliases.zsh " ]]; then
    aliases_file="$DOTFILES_DIR/configs/aliases.zsh"
    if [[ -f "$aliases_file" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            log_info "Uploading aliases.zsh..."
            scp "$aliases_file" "$REMOTE_HOST:/tmp/aliases.zsh.sync"
        else
            log_info "Would upload: $aliases_file -> $REMOTE_HOST:/tmp/aliases.zsh.sync"
        fi
    fi
fi

if [[ "$DRY_RUN" == false ]]; then
    log_info "Installing files on remote host..."
    echo -e "$file_mappings" | ssh "$REMOTE_HOST" "bash -s" <<< "$REMOTE_SCRIPT"
    log_success "Dotfiles successfully synced to $REMOTE_HOST"
else
    log_info "File mappings that would be processed:"
    echo -e "$file_mappings"
fi

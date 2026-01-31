#!/bin/bash

# Dotfiles Installation Script
# This script creates symbolic links from your home directory to this repo

set -e  # Exit on any error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

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

# Function to create backup
backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$file" "$BACKUP_DIR/"
        log_warning "Backed up existing $file to $BACKUP_DIR"
    fi
}

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ -L "$target" ]]; then
        log_info "Removing existing symlink: $target"
        rm "$target"
    elif [[ -e "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    fi
    
    ln -s "$source" "$target"
    log_success "Created symlink: $target -> $source"
}

log_info "Starting dotfiles installation from $DOTFILES_DIR"

# Install zsh configuration
if [[ -f "$DOTFILES_DIR/configs/zshrc" ]]; then
    create_symlink "$DOTFILES_DIR/configs/zshrc" "$HOME/.zshrc"
fi

# Install aliases
if [[ -f "$DOTFILES_DIR/configs/aliases.zsh" ]]; then
    # Create Oh My Zsh custom directory if it doesn't exist
    mkdir -p "$HOME/.oh-my-zsh/custom"
    create_symlink "$DOTFILES_DIR/configs/aliases.zsh" "$HOME/.oh-my-zsh/custom/aliases.zsh"
fi

# Install git configuration
if [[ -f "$DOTFILES_DIR/configs/gitconfig" ]]; then
    create_symlink "$DOTFILES_DIR/configs/gitconfig" "$HOME/.gitconfig"
fi

# Install vim configuration
if [[ -f "$DOTFILES_DIR/configs/vimrc" ]]; then
    create_symlink "$DOTFILES_DIR/configs/vimrc" "$HOME/.vimrc"
fi

# SSH config handling (template only - user must customize)
if [[ -f "$DOTFILES_DIR/configs/ssh_config_template" ]]; then
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        mkdir -p "$HOME/.ssh"
        mkdir -p "$HOME/.ssh/sockets"  # For SSH connection multiplexing
        cp "$DOTFILES_DIR/configs/ssh_config_template" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        log_success "Created SSH config from template. Please customize it for your needs."
    else
        log_warning "SSH config already exists. Template available at: $DOTFILES_DIR/configs/ssh_config_template"
    fi
fi

# Check if Oh My Zsh is installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_warning "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
fi

log_success "Dotfiles installation completed!"
log_info "Backup created at: $BACKUP_DIR"
log_info ""
log_info "Next steps:"
log_info "1. Customize ~/.gitconfig.local with your name and email"
log_info "2. Customize ~/.ssh/config with your server details"
log_info "3. Add machine-specific settings to ~/.zshrc.local"
log_info "4. Add machine-specific aliases to ~/.aliases.local"
log_info "5. Restart your shell or run: source ~/.zshrc"

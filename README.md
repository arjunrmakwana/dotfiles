# Dotfiles Management System

This repository contains configuration files (dotfiles) that can be synchronized across multiple machines including your laptop and remote nodes.

## Quick Start

### Initial Setup (First Time)
```bash
# Clone this repository to your home directory
cd ~
git clone <your-repo-url> dotfiles
cd dotfiles
./install.sh
```

### Sync to Remote Nodes
```bash
# From your laptop, sync to a remote node
./sync-remote.sh user@remote-host

# Or sync specific files only
./sync-remote.sh user@remote-host --files="zshrc,aliases"
```

### Update Dotfiles
```bash
# Pull latest changes
./update.sh

# Push your local changes
./push.sh "commit message"
```

## Included Configurations

- **Shell**: `.zshrc` with Oh My Zsh configuration
- **Aliases**: Custom shell aliases
- **SSH**: SSH client configuration (with privacy handling)
- **Git**: Git configuration
- **Vim**: Basic vim configuration

## File Structure

```
dotfiles/
├── configs/           # Actual dotfiles
│   ├── zshrc
│   ├── aliases.zsh
│   ├── gitconfig
│   ├── vimrc
│   └── ssh_config_template
├── scripts/           # Management scripts
├── install.sh         # Initial installation
├── sync-remote.sh     # Sync to remote machines
├── update.sh          # Pull updates
└── push.sh            # Push changes
```

## Security Notes

- SSH config contains hostname-specific information that may not apply to all machines
- Private keys and sensitive information are never synced
- Use the provided templates and customize per machine as needed

## Customization

Each machine can have local customizations in:
- `~/.zshrc.local` - Local shell configurations
- `~/.aliases.local` - Local aliases
- `~/.gitconfig.local` - Local git settings

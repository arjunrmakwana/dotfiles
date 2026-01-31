# Dotfiles Usage Guide

## Complete Setup Instructions

### Step 1: Initial Setup

1. **Create a Git repository** (on GitHub, GitLab, or any Git hosting service):
   ```bash
   # On GitHub/GitLab, create a new repository called 'dotfiles'
   ```

2. **Initialize the dotfiles repository**:
   ```bash
   cd ~/Desktop/dotfiles
   git init
   git add .
   git commit -m "Initial dotfiles setup"
   git branch -M main
   git remote add origin https://github.com/yourusername/dotfiles.git
   git push -u origin main
   ```

3. **Install dotfiles on your laptop**:
   ```bash
   cd ~/Desktop/dotfiles
   ./install.sh
   ```

### Step 2: Customize for Your Environment

1. **Set up Git configuration**:
   ```bash
   # Create local git config
   echo '[user]' > ~/.gitconfig.local
   echo '    name = Your Name' >> ~/.gitconfig.local
   echo '    email = your.email@example.com' >> ~/.gitconfig.local
   ```

2. **Add machine-specific settings**:
   ```bash
   # Local shell customizations
   echo 'export EDITOR=vim' > ~/.zshrc.local
   echo 'export PATH=$PATH:/your/custom/path' >> ~/.zshrc.local
   
   # Local aliases
   echo 'alias myserver="ssh user@my-server.com"' > ~/.aliases.local
   ```

### Step 3: Sync to Remote Machines

1. **Sync all configurations to a remote server**:
   ```bash
   ./sync-remote.sh user@remote-server.com
   ```

2. **Sync only specific files**:
   ```bash
   ./sync-remote.sh user@remote-server.com --files="zshrc,aliases.zsh"
   ```

3. **Test sync without making changes**:
   ```bash
   ./sync-remote.sh user@remote-server.com --dry-run
   ```

### Step 4: Maintain Your Dotfiles

1. **Update configurations**:
   ```bash
   # Edit your configurations
   vim configs/zshrc
   
   # Commit and push changes
   ./push.sh "Updated shell prompt"
   ```

2. **Pull updates from other machines**:
   ```bash
   ./update.sh
   ```

3. **Update without reinstalling**:
   ```bash
   ./update.sh --no-install
   ```

## Advanced Usage

### Using Your Remote Development Server Alias

Based on your current setup, here's how to integrate your AWS dev server:

```bash
# Add to ~/.aliases.local (machine-specific)
echo 'alias sshdev="ssh dev-dsk-arjunmkw-2b-4998fc23.us-west-2.amazon.com"' > ~/.aliases.local

# Or add to the main aliases file to sync across all machines
echo 'alias sshdev="ssh dev-dsk-arjunmkw-2b-4998fc23.us-west-2.amazon.com"' >> configs/aliases.zsh
```

### Syncing to Your AWS Development Server

```bash
# Sync your dotfiles to your AWS dev server
./sync-remote.sh dev-dsk-arjunmkw-2b-4998fc23.us-west-2.amazon.com

# Or use the alias after setting it up
./sync-remote.sh $(grep 'sshdev=' ~/.aliases.local | cut -d'"' -f2)
```

### Custom SSH Configuration

Since you have AWS-specific SSH configuration, you can:

1. **Keep machine-specific SSH configs** (recommended):
   - Your laptop keeps its current `~/.ssh/config` with WSSH settings
   - Remote servers get basic SSH config from the template

2. **Or create a unified SSH config**:
   ```bash
   # Copy your current SSH config to the template
   cp ~/.ssh/config configs/ssh_config_template
   # Edit and remove sensitive/machine-specific parts
   vim configs/ssh_config_template
   ```

### Workflow Examples

#### Daily Development Workflow
```bash
# Make changes to your configurations
vim configs/zshrc

# Test locally
source ~/.zshrc

# Commit and push changes
./push.sh "Added new environment variable"

# Sync to your development server
./sync-remote.sh dev-dsk-arjunmkw-2b-4998fc23.us-west-2.amazon.com
```

#### Setting Up a New Machine
```bash
# Clone and install on new machine
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

# Customize for this specific machine
echo 'export LOCAL_VAR=value' > ~/.zshrc.local
```

#### Working with Multiple Remote Servers
```bash
# Sync to development environment
./sync-remote.sh dev-server.com

# Sync to staging environment
./sync-remote.sh staging-server.com

# Sync only essential files to production (be careful!)
./sync-remote.sh prod-server.com --files="vimrc,gitconfig"
```

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connection first
ssh -o ConnectTimeout=10 user@server.com echo "test"

# Check SSH agent
ssh-add -l

# For AWS servers, ensure WSSH is working
wssh status
```

### Git Issues
```bash
# If pushing fails, check remote
git remote -v

# Set up remote if missing
git remote add origin https://github.com/yourusername/dotfiles.git
```

### Rollback Changes
```bash
# Your original files are backed up in timestamped directories
ls ~/.dotfiles_backup_*

# Restore if needed
cp ~/.dotfiles_backup_YYYYMMDD_HHMMSS/.zshrc ~/.zshrc
```

## Security Best Practices

1. **Never commit sensitive information**:
   - SSH private keys
   - Passwords or API tokens
   - Machine-specific hostnames (use templates)

2. **Use local configuration files**:
   - `~/.zshrc.local` for sensitive environment variables
   - `~/.aliases.local` for server-specific aliases
   - `~/.gitconfig.local` for personal Git settings

3. **Review before syncing**:
   - Always use `--dry-run` first on production servers
   - Keep production configs minimal

## File Organization Summary

```
dotfiles/
├── configs/              # Version-controlled configurations
│   ├── zshrc            # Shell configuration
│   ├── aliases.zsh      # Common aliases
│   ├── gitconfig        # Git configuration
│   ├── vimrc            # Vim configuration
│   └── ssh_config_template  # SSH template
├── install.sh           # Local installation
├── sync-remote.sh       # Remote synchronization
├── update.sh           # Pull updates
├── push.sh             # Commit and push
└── README.md           # Main documentation
```

Local customization files (not version controlled):
- `~/.zshrc.local`
- `~/.aliases.local`  
- `~/.gitconfig.local`
- `~/.vimrc.local`

This system keeps your configurations synchronized while allowing machine-specific customizations and maintaining security.

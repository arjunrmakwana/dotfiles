# ==============================================
# CUSTOM ALIASES
# ==============================================

# Your original personal aliases
alias ltr='ls -ltr'
alias altr='ls -altr'
alias sshrd='ssh dev-dsk-arjunmkw-2b-4998fc23.us-west-2.amazon.com'

# Load local aliases if they exist (machine-specific)
[[ -f ~/.aliases.local ]] && source ~/.aliases.local

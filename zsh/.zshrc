source "${HOME}/.zsh/aliases.sh"
export PATH="$HOME/.local/bin:$PATH"

alias ls='eza --color=always --icons --group-directories-first'  
alias ll='eza -la --color=always --icons --group-directories-first'

eval "$(starship init zsh)"

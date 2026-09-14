source "${HOME}/.shell/env.sh"
source "${HOME}/.shell/aliases.sh"
source "${HOME}/.shell/functions.sh"
export PATH="$HOME/.local/bin:$PATH"

alias bashconfig="${EDITOR:-vim} ~/.bashrc"
alias bashsource="source ~/.bashrc"


[[ -s "$HOME/.pythonbrew/etc/bashrc" ]] && source "$HOME/.pythonbrew/etc/bashrc"

rvm_script=$HOME/.rvm/scripts/rvm
if [[ -s $rvm_script ]]
then
    source $rvm_script
fi

source "${HOME}/dotfiles/zsh/aliases.sh"

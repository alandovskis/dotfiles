
PATH="${HOME}/bin:${HOME}/.rvm/bin:${PATH}"
PATH="/usr/local/texlive/2016/bin/x86_64-darwin:${PATH}"
PATH="/usr/local/opt/emacs-mac/bin:${PATH}"
PATH="/usr/local/opt/git/bin:${PATH}"
PATH="/usr/local/opt/vim/bin:${PATH}"
export PATH

# -------------
# | Variables |
# -------------
# General
export SITE_DIR="$HOME/Sites"
export DROPBOX_DIR="$HOME/Dropbox"

# Interests
export URBANISM_DIR="$DROPBOX_DIR/urbanism"

# Programming
export PYTHON_DIR="$DROPBOX_DIR/python"
export RUBY_DIR="$DROPBOX_DIR/ruby"
export RAILS_DIR="$RUBY_DIR/rails"

[[ -s "$HOME/.pythonbrew/etc/bashrc" ]] && source "$HOME/.pythonbrew/etc/bashrc"

rvm_script=$HOME/.rvm/scripts/rvm
if [[ -s $rvm_script ]]
then
    source $rvm_script
fi

export EDITOR="vim"

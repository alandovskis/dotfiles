# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="alexlandovskis"

# Example aliases
alias zshconfig="emacs ~/.zshrc"
alias ohmyzsh="emacs ~/.oh-my-zsh"
alias zshsource="source ~/.zshrc"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(brew bundler gem git git-flow mercurial rvm vagrant)

# Do not add commands with a prefix of a space to the history.
HIST_IGNORE_SPACE="true"

fpath=(/usr/local/share/zsh-completions $fpath)

source $ZSH/oh-my-zsh.sh

autoload -U colors
colors
setopt prompt_subst

umask 007

[[ -s "$HOME/.pythonbrew/etc/bashrc" ]] && source "$HOME/.pythonbrew/etc/bashrc"

rvm_script=$HOME/.rvm/scripts/rvm
if [[ -s $rvm_script ]]
then
    source $rvm_script
fi
# -----------
# | Aliases |
# -----------
# General
alias app="cd $APPLICATION_DIR"
alias doc="cd $DOCUMENT_DIR"
alias mov="cd $MOVIE_DIR"
alias img="cd $IMAGE_DIR"
alias mus="cd $MUSIC_DIR"
alias sit="cd $SITE_DIR"
alias dow="cd $DOWNLOAD_DIR"
alias dbox="cd $DROPBOX_DIR"

# ls
alias ls=" ls"
alias ll='ls -l'
alias la='ls -al'

# Ping
alias pingg="ping -c 4 google.com"
alias pingr="ping -c 4 192.168.100.1"
alias pingns="ping -c 4 8.8.8.8; ping -c 4 8.8.4.4"
alias pinga="pingr && pingns && pingg"

# Interests
alias urbs="cd $URBANISM_DIR"

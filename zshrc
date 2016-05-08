# Path to your oh-my-zsh installation.
export ZSH=/Users/alex/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="alexlandovskis"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(brew bundler gem git git-flow mercurial rvm vagrant)
fpath=(/usr/local/share/zsh-completions $fpath)

# User configuration

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#

umask 007
alias zshconfig="emacs ~/.zshrc"
alias ohmyzsh="emacs ~/.oh-my-zsh"
alias zshsource="source ~/.zshrc"

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

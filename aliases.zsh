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
alias sshr="ssh vyatta@router"

# Programming
alias transit="pushd $RUBY_DIR/transit-tools >& /dev/null; pushd +1 >& /dev/null; popd >& /dev/null; pushd $RAILS_DIR/transit &> /dev/null"

# Git
alias gst="git status "
alias ga="git add "
alias gco="git checkout "
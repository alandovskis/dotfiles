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
alias ll='ls -l'
alias la='ls -al'

# Ping
alias pingg="ping -c 4 google.com"
alias pingr="ping -c 4 192.168.100.1"
alias pingns="ping -c 4 8.8.8.8; ping -c 4 8.8.4.4"
alias pinga="pingr && pingns && pingg"

alias cu="cd $CONCORDIA_DIR"
alias sshl="ssh j_landov@login.encs.concordia.ca"
alias c476="cd $COMP476_DIR"
alias e393="cd $ENCS393_DIR"
alias s422="cd $SOEN422_DIR"
alias s422proj="cd $SOEN422_PROJECT_DIR"
alias serteensy="minicom -D /dev/tty.usbmodem12341"
alias serbonea="minicom -D /dev/tty.usbserial-TIVHL2KQA"
alias serboneb="minicom -D /dev/tty.usbserial-TIVHL2KQB"
alias xbee="minicom -D /dev/tty.usbserial-A1011FEB -b 9600"

# Interests
alias urbs="cd $URBANISM_DIR"
alias sshr="ssh vyatta@router"

# Programming
alias transit="pushd $RUBY_DIR/transit-tools >& /dev/null; pushd +1 >& /dev/null; popd >& /dev/null; pushd $RAILS_DIR/transit &> /dev/null"

# Git
alias gst="git status "
alias ga="git add "
alias gco="git checkout "
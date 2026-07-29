# Directory shortcuts
alias app="cd $APPLICATION_DIR"
alias doc="cd $DOCUMENT_DIR"
alias mov="cd $MOVIE_DIR"
alias img="cd $IMAGE_DIR"
alias mus="cd $MUSIC_DIR"
alias dow="cd $DOWNLOAD_DIR"

# ls
alias ls='eza --color=always --icons --group-directories-first'
alias ll='eza -la --color=always --icons --group-directories-first'
alias la='ls -al'

# Ping
alias pingg="ping -c 4 google.com"
alias pingr="ping -c 4 192.168.100.1"
alias pingns="ping -c 4 8.8.8.8; ping -c 4 8.8.4.4"
alias pinga="pingr && pingns && pingg"

ARDUINO_TOOLS_DIR="/Applications/Arduino.app/Contents/Resources/Java/hardware/tools"

PATH="${HOME}/bin:${HOME}/.rvm/bin:${PATH}"
PATH="/usr/local/texlive/2012/bin/universal-darwin:${PATH}"
PATH="${ARDUINO_TOOLS_DIR}/teensy.app/Contents/MacOS:${PATH}"
PATH="${ARDUINO_TOOLS_DIR}/avr/bin:${PATH}"
PATH="/usr/local/opt/emacs-mac/bin:${PATH}"
PATH="/usr/local/opt/vim/bin:${PATH}"
export PATH

export LDFLAGS="-L/usr/local/opt/openssl/lib -L/usr/local/opt/gettext/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include -I/usr/local/opt/gettext/include"

# -------------
# | Variables |
# -------------
# General
export DOCUMENT_DIR="$HOME/Documents"
export MOVIE_DIR="$HOME/Movies"
export IMAGE_DIR="$HOME/Photos"
export MUSIC_DIR="$HOME/Music"
export SITE_DIR="$HOME/Sites"
export DOWNLOAD_DIR="$HOME/Downloads"
export APPLICATION_DIR="/Applications"
export DROPBOX_DIR="$HOME/Dropbox"

# Interests
export URBANISM_DIR="$DROPBOX_DIR/urbanism"

# Programming
export PYTHON_DIR="$DROPBOX_DIR/python"
export RUBY_DIR="$DROPBOX_DIR/ruby"
export RAILS_DIR="$RUBY_DIR/rails"

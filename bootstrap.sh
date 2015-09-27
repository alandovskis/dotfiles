DOTFILES="${HOME}/dotfiles"

CURLRC_SRC="${DOTFILES}/curlrc"
CURLRC_DST="${HOME}/.curlrc"
ln -s ${CURLRC_SRC} ${CURLRC_DST}

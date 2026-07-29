# Shared shell functions (bash + zsh).

unblock() {
    kill "$(lsof -ti:"$1")"
}

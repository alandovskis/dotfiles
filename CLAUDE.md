# dotfiles

Personal dotfiles for shell and development tools, managed via symlinks or GNU Stow.

## Structure

See [STRUCTURE.md](STRUCTURE.md) for the directory layout.

## Setup

```sh
stow -t "$HOME" git zsh bash shell curl gem rspec jetbrains kdiff3
ln -sf "$(pwd)/claude/.claude" "$HOME/.claude"
```

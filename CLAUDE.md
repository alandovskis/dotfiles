# dotfiles

Personal dotfiles for shell and development tools, managed via symlinks or GNU Stow.

## Structure

- `zsh/` — zshenv, zshrc, zlogin, aliases
- `git/` — gitconfig with delta pager and aliases; diff-so-fancy as submodule
- `claude/` — Claude Code config (symlinked to `~/.claude/`); contains commands, hooks, skills, settings.json
- `curl/`, `gem/`, `rspec/`, `jetbrains/`, `kdiff3/` — tool configs

## Setup

```sh
stow -t "$HOME" git zsh curl gem rspec jetbrains kdiff3
ln -sf "$(pwd)/claude/.claude" "$HOME/.claude"
```

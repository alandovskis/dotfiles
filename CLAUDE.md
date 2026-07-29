# dotfiles

Personal dotfiles for shell and development tools, managed via symlinks or GNU Stow.

## Structure

- `shell/.shell/` — aliases, functions, and env vars shared between bash and zsh
- `zsh/` — zshenv, zshrc, zlogin (sources `shell/.shell/`)
- `bash/` — bashrc, bash_profile (sources `shell/.shell/`)
- `git/` — gitconfig with delta pager and aliases; diff-so-fancy as submodule
- `claude/` — Claude Code config (symlinked to `~/.claude/`); contains commands, hooks, skills, settings.json
- `curl/`, `gem/`, `rspec/`, `jetbrains/`, `kdiff3/` — tool configs

## Setup

```sh
stow -t "$HOME" git zsh bash shell curl gem rspec jetbrains kdiff3
ln -sf "$(pwd)/claude/.claude" "$HOME/.claude"
```

# dotfiles

Personal dotfiles and small utility scripts for shell and development tools.

## Contents

- `curl/.curlrc` - curl defaults (progress bar, auto referer, timeout).
- `gem/.gemrc` - disable gem documentation by default.
- `git/.gitconfig` - git defaults, aliases, delta integration, diff3 conflicts.
- `iterm2/` - iTerm2 color preset (Zenburn).
- `jetbrains/.ideavimrc` - IdeaVim mappings for navigation, refactors, and VCS.
- `kdiff3/.kdiff3rc` - KDiff3 UI and merge preferences.
- `rspec/.rspec` - colorized RSpec output.
- `zsh/` - zsh environment setup, login config, and aliases.

## Zsh notes

- `zsh/.zshenv` sets PATH entries and common directory environment variables.
- `zsh/.zshrc` loads `zsh/.zsh/aliases.sh`.
- `zsh/.zlogin` loads RVM if present.

## Git notes

- Uses `delta` as the pager and interactive diff filter.
- Adds convenience aliases like `st`, `co`, `lol`, and `lola`.

## IdeaVim mappings (JetBrains)

Leader key is Space. Highlights:

- Navigation: `gc` comment line, `gd` go to implementation, `gD` go to declaration,
  `j`/`k` move between methods.
- Search/replace: `Space/` find in path, `Space*` replace in path.
- Files: `Spacefr` recent files, `Spacefs` save all, `Spacefx` new scratch file.
- Git: `Spacega` add, `Spacegbc` create branch, `SpacegB` branches, `Spacegl` log,
  `Spacegm` merge, `Spacegr` rebase, `Spacegzz` stash/unstash.
- Jump: `Spacejc` class, `Spacejf` file, `Spacejs` symbol, `Spacejt` test.
- Refactor: `SpacerM` extract method, `Spacern` rename, `Spacerp` introduce
  parameter, `Spacerv` introduce variable.
- Run/debug: `Spaced` debug, `Spacex` run, `SpaceX` run configuration.

## Usage

Copy or symlink the files you want into your home directory or tool-specific
config locations.

## Setup

From the repo root, symlink what you want:

```sh
ln -sf "$(pwd)/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$(pwd)/zsh/.zshenv" "$HOME/.zshenv"
ln -sf "$(pwd)/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$(pwd)/zsh/.zlogin" "$HOME/.zlogin"
ln -sf "$(pwd)/zsh/.zsh" "$HOME/.zsh"
ln -sf "$(pwd)/curl/.curlrc" "$HOME/.curlrc"
ln -sf "$(pwd)/gem/.gemrc" "$HOME/.gemrc"
ln -sf "$(pwd)/rspec/.rspec" "$HOME/.rspec"
ln -sf "$(pwd)/jetbrains/.ideavimrc" "$HOME/.ideavimrc"
ln -sf "$(pwd)/kdiff3/.kdiff3rc" "$HOME/.kdiff3rc"
```

# dotfiles

Personal dotfiles for shell, editor, Git, AI agent, and small tool configuration.

## Layout

- `ai/.claude/` — Claude Code settings, hooks, commands, routines, rules, and skills.
- `ai/.codex/` — Codex config and a `skills` symlink to `../.claude/skills`.
- `curl/.curlrc` — curl defaults.
- `git/.gitconfig` — Git aliases, delta pager, and merge/diff defaults.
- `jetbrains/.ideavimrc` — IdeaVim mappings.
- `kdiff3/.kdiff3rc` — KDiff3 preferences.
- `macos/` and `linux/` — platform-specific config files.
- `ruby/.gemrc` and `ruby/.rspec` — Ruby tool defaults.
- `shell/.shell/` — aliases, functions, and env vars shared between bash and zsh.
- `zsh/` — zsh environment, login config, and rc file (sources `shell/.shell/`).
- `bash/` — bash profile and rc file (sources `shell/.shell/`).

## Setup

Use GNU Stow for the simple packages you want:

```sh
stow -t "$HOME" git zsh bash shell curl ruby jetbrains kdiff3
```

Link AI-agent config explicitly:

```sh
mkdir -p "$HOME/.codex"
ln -sf "$(pwd)/ai/.codex/config.toml" "$HOME/.codex/config.toml"
ln -sfn "$(pwd)/ai/.codex/skills" "$HOME/.codex/skills"
ln -sfn "$(pwd)/ai/.claude" "$HOME/.claude"
```

Or create individual symlinks for everything:

```sh
ln -sf "$(pwd)/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$(pwd)/zsh/.zshenv" "$HOME/.zshenv"
ln -sf "$(pwd)/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$(pwd)/zsh/.zlogin" "$HOME/.zlogin"
ln -sf "$(pwd)/bash/.bashrc" "$HOME/.bashrc"
ln -sf "$(pwd)/bash/.bash_profile" "$HOME/.bash_profile"
ln -sfn "$(pwd)/shell/.shell" "$HOME/.shell"
ln -sf "$(pwd)/curl/.curlrc" "$HOME/.curlrc"
ln -sf "$(pwd)/ruby/.gemrc" "$HOME/.gemrc"
ln -sf "$(pwd)/ruby/.rspec" "$HOME/.rspec"
ln -sf "$(pwd)/jetbrains/.ideavimrc" "$HOME/.ideavimrc"
ln -sf "$(pwd)/kdiff3/.kdiff3rc" "$HOME/.kdiff3rc"
ln -sfn "$(pwd)/ai/.claude" "$HOME/.claude"
```

## Notes

- Codex and Claude share custom skills through `ai/.codex/skills -> ../.claude/skills`.
- The Codex Atlassian MCP server uses `mcp-remote` with Atlassian's Streamable HTTP endpoint. Check it with `codex mcp get atlassian`.

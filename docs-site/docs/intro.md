---
sidebar_position: 1
---

# dotfiles

Personal dotfiles for shell, editor, Git, AI agent, and small tool configuration.

See [Directory Structure](./structure.md) for the directory layout.

## Setup

Use GNU Stow for the simple packages you want:

```sh
stow -t "$HOME" git shell curl ruby jetbrains kdiff3 terminal
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
mkdir -p "$HOME/.config/ghostty"
ln -sf "$(pwd)/terminal/.config/ghostty/config" "$HOME/.config/ghostty/config"
ln -sf "$(pwd)/shell/.zshenv" "$HOME/.zshenv"
ln -sf "$(pwd)/shell/.zshrc" "$HOME/.zshrc"
ln -sf "$(pwd)/shell/.zlogin" "$HOME/.zlogin"
ln -sf "$(pwd)/shell/.bashrc" "$HOME/.bashrc"
ln -sf "$(pwd)/shell/.bash_profile" "$HOME/.bash_profile"
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

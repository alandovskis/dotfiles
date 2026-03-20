#!/usr/bin/env bash
# Blocks dangerous bash commands before they execute.
#
# Covered patterns:
#   - rm -rf on /, ~, $HOME, or wildcard (*)
#   - sudo rm -rf on system paths
#   - git push --force / --delete / :branch (remote delete)
#   - git reset --hard
#   - git clean -f (untracked file deletion)
#   - git checkout -- . / git restore . (discard working tree)
#   - git branch -D on protected branches
#   - SQL DROP TABLE/DATABASE/SCHEMA/USER/ROLE, TRUNCATE
#   - dd writing to a block device (of=/dev/sdX, /dev/nvme*, /dev/disk*)
#   - Shell redirection to block devices (> /dev/sda)
#   - mkfs (filesystem formatting)
#   - shred / wipefs (secure erasure)
#   - truncate -s 0 (zero a file's contents)
#   - crontab -r (delete crontab without confirmation)
#   - kill -9 1 / killall init (crash the system)
#   - iptables -F / ufw reset (flush firewall rules)
#   - passwd / chpasswd (change passwords)
#   - Piping curl/wget output directly to a shell
#   - Fork bomb pattern
#   - Shell redirection to /etc/

set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Strip the content of "human text" arguments — commit messages, PR bodies,
# titles, and descriptions — before pattern-matching.  These flags always carry
# human-readable prose, never executable code, so dangerous-sounding words
# inside them are false positives.
#
# Examples of false positives that are fixed:
#   git commit -m "blocks rm -rf on dangerous paths"   →  git commit -m ""
#   gh pr create --body "protect against DROP TABLE"   →  gh pr create --body ""
#
# We intentionally do NOT strip -c/-e/--execute arguments because those
# contain SQL or shell code that the patterns should actually inspect.
#
# The original $cmd is preserved for error output so the user sees exactly
# what was blocked.
cmd_for_matching=$(printf '%s' "$cmd" | sed \
    -e 's/\( -m \+\)"[^"]*"/\1""/g' \
    -e 's/\( -m \+\)'"'"'[^'"'"']*'"'"'/\1'"'"''"'"'/g' \
    -e 's/\(--message \+\)"[^"]*"/\1""/g' \
    -e 's/\(--message \+\)'"'"'[^'"'"']*'"'"'/\1'"'"''"'"'/g' \
    -e 's/\(--body \+\)"[^"]*"/\1""/g' \
    -e 's/\(--body \+\)'"'"'[^'"'"']*'"'"'/\1'"'"''"'"'/g' \
    -e 's/\(--title \+\)"[^"]*"/\1""/g' \
    -e 's/\(--title \+\)'"'"'[^'"'"']*'"'"'/\1'"'"''"'"'/g' \
    -e 's/\(--description \+\)"[^"]*"/\1""/g' \
    -e 's/\(--description \+\)'"'"'[^'"'"']*'"'"'/\1'"'"''"'"'/g')
# For "git commit -F - <<MARKER", the heredoc body IS the commit message.
# Keep only the first line so none of the message text is pattern-matched.
if printf '%s' "$cmd_for_matching" | head -1 | grep -qE '^\s*git\s+commit\b.*-F\b'; then
    cmd_for_matching=$(printf '%s' "$cmd_for_matching" | head -1)
fi

deny() {
    printf 'BLOCKED: %s\n\nCommand: %s\n' "$1" "$cmd" >&2
    exit 2
}

# rm -rf on dangerous targets: /, /*, ~, $HOME, or bare *
# The target must be bounded (followed by whitespace or end of string) to avoid
# false positives on legitimate paths like /tmp/build or ~/projects.
# Handles: -rf, -fr, and the flags in any order.
if echo "$cmd_for_matching" | grep -qE '\brm\b[^|&;]*(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)[^|&;]*[ \t](/\*?(\s|$)|~(\s|$)|\$(\{?HOME\}?)(\s|$)|\./?\s*$)'; then
    deny "rm -rf on root (/), home (~, \$HOME), current dir (.), or wildcard is not allowed."
fi

# sudo rm -rf on system directories
if echo "$cmd_for_matching" | grep -qE '\bsudo\b[^|&;]*\brm\b[^|&;]*(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[^|&;]*/(etc|usr|bin|sbin|lib|boot|var)\b'; then
    deny "sudo rm -rf on a system path (/etc, /usr, /bin, /sbin, /lib, /boot, /var) is not allowed."
fi

# git push --force or -f — but allow --force-with-lease (safer alternative)
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\bpush\b[^|&;]*(\s-f\b|\s--force\b)'; then
    if ! echo "$cmd_for_matching" | grep -qE 'force-with-lease'; then
        deny "git push --force is blocked to prevent overwriting shared history. Use --force-with-lease instead."
    fi
fi

# git push --delete (modern syntax for remote branch deletion)
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\bpush\b[^|&;]*--delete\b'; then
    deny "Deleting a remote branch via 'git push --delete' is blocked."
fi

# git push origin :branch (legacy syntax for remote branch deletion)
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\bpush\b[^|&;]+[ \t]:\S+'; then
    deny "Deleting a remote branch via 'git push origin :branch' is blocked."
fi

# git reset --hard
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\breset\b[^|&;]*--hard'; then
    deny "git reset --hard discards uncommitted changes and cannot be undone. Stash your work first."
fi

# git clean -f (any combination of flags including f)
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\bclean\b[^|&;]*-[a-zA-Z]*f'; then
    deny "git clean -f permanently deletes untracked files. Use 'git clean -n' (dry-run) to preview first."
fi

# git checkout -- . (discard all working tree changes)
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\bcheckout\b[^|&;]+--[ \t]+\.'; then
    deny "git checkout -- . discards all working directory changes. Stash your work first."
fi

# git restore . (discard all changes)
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\brestore\b[^|&;]*\s\.(\s|$)'; then
    deny "git restore . discards all working directory changes. Stash your work first."
fi

# git branch -D on protected branch names
if echo "$cmd_for_matching" | grep -qE '\bgit\b[^|&;]*\bbranch\b[^|&;]*\s-D\b[^|&;]*(main|master|develop|development|production|release)\b'; then
    deny "Deleting a protected branch (main, master, develop, production, release) is not allowed."
fi

# SQL DROP TABLE / DROP DATABASE / DROP SCHEMA / DROP USER / TRUNCATE
# The TRUNCATE pattern requires the next token to start with a letter to avoid
# matching the 'truncate' CLI utility (e.g. truncate -s 0).
if echo "$cmd_for_matching" | grep -iqE '\b(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX|USER|ROLE)|TRUNCATE\s+(TABLE\s+)?[a-zA-Z_"])\b'; then
    deny "SQL DROP/TRUNCATE detected. These operations destroy data or access permanently."
fi

# dd writing to a block device — explicitly allow /dev/null, block everything else.
# Matches /dev/sd*, /dev/hd*, /dev/nvme*, /dev/disk*, /dev/vd*, /dev/xvd*, etc.
if echo "$cmd_for_matching" | grep -qE '\bdd\b[^|&;]*\bof=/dev/' && ! echo "$cmd_for_matching" | grep -qE '\bof=/dev/null\b'; then
    deny "dd writing to a block device (of=/dev/...) is blocked. This can destroy filesystem data."
fi

# Shell redirection to a block device (cat /dev/zero > /dev/sda, etc.)
if echo "$cmd_for_matching" | grep -qE '>[^>][^|&;]*/dev/(sd[a-z]|hd[a-z]|nvme[0-9]|disk[0-9]|vd[a-z]|xvd[a-z])'; then
    deny "Shell redirection to a block device is blocked. This can destroy filesystem data."
fi

# mkfs — formats a filesystem
if echo "$cmd_for_matching" | grep -qE '\bmkfs(\.[a-z0-9]+)?\b'; then
    deny "mkfs (filesystem formatting) is blocked. This operation destroys all data on the target."
fi

# shred — securely erases files or devices (irrecoverable)
if echo "$cmd_for_matching" | grep -qE '\bshred\b'; then
    deny "shred is blocked. It overwrites files irrecoverably."
fi

# wipefs — erases filesystem signatures from a device
if echo "$cmd_for_matching" | grep -qE '\bwipefs\b'; then
    deny "wipefs is blocked. It erases filesystem signatures, making devices unreadable."
fi

# truncate -s 0 — zeros a file's contents without removing it
if echo "$cmd_for_matching" | grep -qE '\btruncate\b[^|&;]*-s\s*0\b'; then
    deny "truncate -s 0 silently destroys file contents. The file remains but all data is gone."
fi

# crontab -r — deletes the entire crontab with no confirmation prompt
if echo "$cmd_for_matching" | grep -qE '\bcrontab\b[^|&;]*-r\b'; then
    deny "crontab -r deletes your entire crontab with no confirmation and no undo."
fi

# kill -9 PID 1 / killall init|systemd — crashes the system
if echo "$cmd_for_matching" | grep -qE '\bkill\b[^|&;]*(-9|-SIGKILL)[^|&;]*\b1\b'; then
    deny "Sending SIGKILL to PID 1 causes an immediate system crash."
fi
if echo "$cmd_for_matching" | grep -qE '\bkillall\b[^|&;]*(-9|-SIGKILL)[^|&;]*\b(init|systemd)\b'; then
    deny "Sending SIGKILL to init/systemd causes an immediate system crash."
fi

# iptables -F / ufw reset / nft flush — flushes all firewall rules
if echo "$cmd_for_matching" | grep -qE '\biptables\b[^|&;]*-F\b|\bufw\b[^|&;]*--reset\b|\bnft\b[^|&;]*\bflush\b'; then
    deny "Flushing firewall rules (iptables -F, ufw --reset, nft flush) removes all network protection."
fi

# passwd / chpasswd — change user passwords
if echo "$cmd_for_matching" | grep -qE '\b(passwd|chpasswd)\b'; then
    deny "Changing passwords (passwd/chpasswd) is blocked to prevent lockouts."
fi

# Pipe downloaded content directly to a shell interpreter
if echo "$cmd_for_matching" | grep -qE '\b(curl|wget)\b[^|&;]*\|[^|&;]*(bash|sh|zsh|fish|ksh|dash)\b'; then
    deny "Piping curl/wget output directly to a shell is a supply-chain security risk. Download the script first and inspect it."
fi

# Fork bomb: :(){:|:&};:
if echo "$cmd_for_matching" | grep -qE ':\(\)\s*\{[^}]*:\s*\|'; then
    deny "Fork bomb pattern detected. This would crash the system."
fi

# Shell redirection to /etc/
if echo "$cmd_for_matching" | grep -qE '>[^>][^|&;]*/etc/[a-zA-Z]'; then
    deny "Shell redirection to /etc/ is blocked. Modifying system config files can break the OS."
fi

exit 0

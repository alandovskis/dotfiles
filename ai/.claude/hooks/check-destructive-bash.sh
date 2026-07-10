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
#   - SQL DROP TABLE/DATABASE/SCHEMA/USER/ROLE, TRUNCATE (when a DB client is present)
#   - dd writing to a block device (of=/dev/sdX, /dev/nvme*, /dev/disk*)
#   - Shell redirection to block devices (> /dev/sda)
#   - mkfs (filesystem formatting)
#   - shred / wipefs (secure erasure)
#   - truncate -s 0 (zero a file's contents)
#   - crontab -r (delete crontab without confirmation)
#   - kill -9 1 / killall init (crash the system)
#   - iptables -F / ufw reset (flush firewall rules)
#   - passwd / chpasswd (change passwords, as a command not a path)
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

# Strip single-quoted heredoc content before pattern matching.
# Heredoc bodies (<<'EOF' ... EOF) are text data — commit messages, PR bodies,
# documentation — not executed shell code. Matching against them causes false
# positives when the text describes dangerous commands.
cmd_check=$(printf '%s\n' "$cmd_for_matching" | awk '
    /<<'"'"'[A-Za-z_]/ {
        s = $0
        sub(/.*<<'"'"'/, "", s)
        sub(/'"'"'.*/, "", s)
        heredoc_end = s
        sub(/<<'"'"'[^'"'"']*'"'"'.*/, "")
        in_heredoc = 1
        print
        next
    }
    in_heredoc {
        if ($0 ~ "^" heredoc_end) in_heredoc = 0
        next
    }
    { print }
')

# True when the top-level command is clearly text output/search AND it does not
# pipe to a shell interpreter. In this context, pattern matches are data, not intent.
# Used to suppress false positives on checks like iptables where grep/echo can mention
# the patterns without executing them.
is_display_cmd=false
if echo "$cmd_check" | grep -qE '^\s*(echo|printf|cat|grep|rg|awk|sed|head|tail|less|more)\b' && \
   ! echo "$cmd_check" | grep -qE '\|\s*(bash|sh|zsh|fish|ksh|dash)\b'; then
    is_display_cmd=true
fi

deny() {
    printf 'BLOCKED: %s\n\nCommand: %s\n' "$1" "$cmd" >&2
    exit 2
}

# --- rm -rf on dangerous targets: /, /*, ~, $HOME, or current dir (.) ---
# The target must be bounded (followed by whitespace or end of string) to avoid
# false positives on legitimate paths like /tmp/build or ~/projects.
if echo "$cmd_check" | grep -qE '\brm\b[^|&;]*(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)[^|&;]*[ \t](/\*?(\s|$)|~(\s|$)|\$(\{?HOME\}?)(\s|$)|\./?\s*$)'; then
    deny "rm -rf on root (/), home (~, \$HOME), current dir (.), or wildcard is not allowed."
fi

# --- sudo rm -rf on system directories ---
if echo "$cmd_check" | grep -qE '\bsudo\b[^|&;]*\brm\b[^|&;]*(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[^|&;]*/(etc|usr|bin|sbin|lib|boot|var)\b'; then
    deny "sudo rm -rf on a system path (/etc, /usr, /bin, /sbin, /lib, /boot, /var) is not allowed."
fi

# --- git push --force or -f (allow --force-with-lease as a safer alternative) ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\bpush\b[^|&;]*(\s-f\b|\s--force\b)'; then
    if ! echo "$cmd_check" | grep -qE 'force-with-lease'; then
        deny "git push --force is blocked to prevent overwriting shared history. Use --force-with-lease instead."
    fi
fi

# --- git push --delete (modern syntax for remote branch deletion) ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\bpush\b[^|&;]*--delete\b'; then
    deny "Deleting a remote branch via 'git push --delete' is blocked."
fi

# --- git push origin :branch (legacy syntax for remote branch deletion) ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\bpush\b[^|&;]+[ \t]:\S+'; then
    deny "Deleting a remote branch via 'git push origin :branch' is blocked."
fi

# --- git reset --hard ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\breset\b[^|&;]*--hard'; then
    deny "git reset --hard discards uncommitted changes and cannot be undone. Stash your work first."
fi

# --- git clean -f ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\bclean\b[^|&;]*-[a-zA-Z]*f'; then
    deny "git clean -f permanently deletes untracked files. Use 'git clean -n' (dry-run) to preview first."
fi

# --- git checkout -- . ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\bcheckout\b[^|&;]+--[ \t]+\.'; then
    deny "git checkout -- . discards all working directory changes. Stash your work first."
fi

# --- git restore . ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\brestore\b[^|&;]*\s\.(\s|$)'; then
    deny "git restore . discards all working directory changes. Stash your work first."
fi

# --- git branch -D on protected branch names ---
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*\bbranch\b[^|&;]*\s-D\b[^|&;]*(main|master|develop|development|production|release)\b'; then
    deny "Deleting a protected branch (main, master, develop, production, release) is not allowed."
fi

# --- SQL DROP / TRUNCATE ---
# Only checked when the command also invokes a database client, to avoid false
# positives when SQL keywords appear in grep patterns, echo output, or comments.
# The TRUNCATE pattern requires the subject to start with a letter (not a flag like -s).
if echo "$cmd_check" | grep -qE '\b(psql|mysql|mariadb|sqlite3|sqlcmd|clickhouse|cockroach)\b'; then
    if echo "$cmd_check" | grep -iqE '\b(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX|USER|ROLE)|TRUNCATE\s+(TABLE\s+)?[a-zA-Z_"])\b'; then
        deny "SQL DROP/TRUNCATE detected. These operations destroy data or access permanently."
    fi
fi

# --- dd writing to a block device (explicitly allow /dev/null) ---
if echo "$cmd_check" | grep -qE '\bdd\b[^|&;]*\bof=/dev/' && \
   ! echo "$cmd_check" | grep -qE '\bof=/dev/null\b'; then
    deny "dd writing to a block device (of=/dev/...) is blocked. This can destroy filesystem data."
fi

# --- Shell redirection to a block device ---
if echo "$cmd_check" | grep -qE '>[^>][^|&;]*/dev/(sd[a-z]|hd[a-z]|nvme[0-9]|disk[0-9]|vd[a-z]|xvd[a-z])'; then
    deny "Shell redirection to a block device is blocked. This can destroy filesystem data."
fi

# --- mkfs ---
if echo "$cmd_check" | grep -qE '\bmkfs(\.[a-z0-9]+)?\b'; then
    deny "mkfs (filesystem formatting) is blocked. This operation destroys all data on the target."
fi

# --- shred ---
if echo "$cmd_check" | grep -qE '\bshred\b'; then
    deny "shred is blocked. It overwrites files irrecoverably."
fi

# --- wipefs ---
if echo "$cmd_check" | grep -qE '\bwipefs\b'; then
    deny "wipefs is blocked. It erases filesystem signatures, making devices unreadable."
fi

# --- truncate -s 0 ---
if echo "$cmd_check" | grep -qE '\btruncate\b[^|&;]*-s\s*0\b'; then
    deny "truncate -s 0 silently destroys file contents. The file remains but all data is gone."
fi

# --- crontab -r ---
if echo "$cmd_check" | grep -qE '\bcrontab\b[^|&;]*-r\b'; then
    deny "crontab -r deletes your entire crontab with no confirmation and no undo."
fi

# --- kill -9 1 / killall init|systemd ---
if echo "$cmd_check" | grep -qE '\bkill\b[^|&;]*(-9|-SIGKILL)[^|&;]*\b1\b'; then
    deny "Sending SIGKILL to PID 1 causes an immediate system crash."
fi
if echo "$cmd_check" | grep -qE '\bkillall\b[^|&;]*(-9|-SIGKILL)[^|&;]*\b(init|systemd)\b'; then
    deny "Sending SIGKILL to init/systemd causes an immediate system crash."
fi

# --- iptables -F / ufw --reset / nft flush ---
# Skipped when the command is clearly text-output/search without a pipe to a shell,
# since documentation or grep results may mention these patterns.
if ! $is_display_cmd; then
    if echo "$cmd_check" | grep -qE '\biptables\b[^|&;]*-F\b|\bufw\b[^|&;]*--reset\b|\bnft\b[^|&;]*\bflush\b'; then
        deny "Flushing firewall rules (iptables -F, ufw --reset, nft flush) removes all network protection."
    fi
fi

# --- passwd / chpasswd as commands (not path references like /etc/passwd) ---
# Anchored to the start of a pipeline segment to avoid matching /etc/passwd in
# commands like: cat /etc/passwd, grep root /etc/passwd, ls -la /etc/passwd
if echo "$cmd_check" | grep -qE '(^|[;&|]|\n)\s*(sudo\s+)?\b(passwd|chpasswd)\b'; then
    deny "Changing passwords (passwd/chpasswd) is blocked to prevent lockouts."
fi

# --- curl/wget piped to a shell ---
if echo "$cmd_check" | grep -qE '\b(curl|wget)\b[^|&;]*\|[^|&;]*(bash|sh|zsh|fish|ksh|dash)\b'; then
    deny "Piping curl/wget output directly to a shell is a supply-chain security risk. Download the script first and inspect it."
fi

# --- Fork bomb ---
if echo "$cmd_check" | grep -qE ':\(\)\s*\{[^}]*:\s*\|'; then
    deny "Fork bomb pattern detected. This would crash the system."
fi

# --- Shell redirection to /etc/ ---
if echo "$cmd_check" | grep -qE '>[^>][^|&;]*/etc/[a-zA-Z]'; then
    deny "Shell redirection to /etc/ is blocked. Modifying system config files can break the OS."
fi

# --- git commit in the dotfiles / .claude repo that stages settings files ---
# Any git add/commit touching ~/.claude/settings.json is a self-modification
# attempt and must require explicit user action outside of Claude.
if echo "$cmd_check" | grep -qE '\bgit\b[^|&;]*(add|commit)\b[^|&;]*(\.claude/settings\.json|claude/\.claude/settings\.json)'; then
    deny "staging or committing Claude Code settings files is blocked to prevent self-modification of agent behaviour. Make this commit manually outside of Claude."
fi

exit 0

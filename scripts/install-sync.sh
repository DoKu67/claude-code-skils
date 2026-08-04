#!/usr/bin/env bash
# Install the background timer that keeps this machine's skills pushed to GitHub.
#
# Run once per machine, from anywhere:
#     ~/.claude/scripts/install-sync.sh
#
# Idempotent — running it again re-installs cleanly over the previous install.
# Uninstall with: ~/.claude/scripts/install-sync.sh --uninstall

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC="${REPO}/scripts/sync-skills.sh"
LABEL="claude-skills-sync"
UNINSTALL=0
[ "${1:-}" = "--uninstall" ] && UNINSTALL=1

say()  { printf '  %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "$SYNC" ] || fail "sync-skills.sh not found at ${SYNC}"
chmod +x "$SYNC"

# ---------------------------------------------------------------- preflight --

preflight() {
  git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || fail "${REPO} is not a git repository"

  local remote
  remote="$(git -C "$REPO" remote get-url origin 2>/dev/null)" || fail "no 'origin' remote configured"
  say "repo:    ${REPO}"
  say "remote:  ${remote}"

  # A fresh machine will not have github.com in known_hosts, and an unattended
  # push would hang on the host-key prompt. Seed it now.
  if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    say "seeding github.com host key into ~/.ssh/known_hosts"
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
    chmod 600 ~/.ssh/known_hosts
  fi

  # The timer runs with no terminal, so a passphrase-protected key or an
  # https remote needing a credential prompt will fail silently every time.
  case "$remote" in
    git@*|ssh://*)
      if ! ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        say "WARNING: ssh to github.com did not authenticate non-interactively."
        say "         The timer cannot answer a passphrase prompt. Check your key,"
        say "         or add it to an agent that persists across logins."
      else
        say "auth:    ssh key works non-interactively"
      fi
      ;;
    https://*)
      say "WARNING: remote is https. Unattended pushes need a credential helper"
      say "         (git config --global credential.helper store) or they will fail."
      ;;
  esac
}

# ------------------------------------------------------------------- linux ---

install_systemd() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
  mkdir -p "$dir"

  cat > "${dir}/${LABEL}.service" <<EOF
[Unit]
Description=Commit and push Claude Code skill changes
Documentation=file://${REPO}/README.md

[Service]
Type=oneshot
ExecStart=${SYNC}
# Don't let a hung network call pile up runs.
TimeoutStartSec=300
EOF

  # OnCalendar + Persistent is the combination that survives the machine being
  # off: if a scheduled run was missed while powered down, it fires on next
  # boot instead of waiting for the following slot. A monotonic timer
  # (OnUnitActiveSec) would silently skip it.
  cat > "${dir}/${LABEL}.timer" <<EOF
[Unit]
Description=Sync Claude Code skills every 6 hours

[Timer]
OnCalendar=*-*-* 00/6:00:00
Persistent=true
OnBootSec=3min
RandomizedDelaySec=60
Unit=${LABEL}.service

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now "${LABEL}.timer" >/dev/null 2>&1 || fail "could not enable the timer"
  say "installed: ${dir}/${LABEL}.timer"

  # Without lingering, user units stop when you log out and do not start on
  # boot until you log in — which defeats "runs whenever the machine is on".
  if [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" = "yes" ]; then
    say "linger:  already enabled"
  elif loginctl enable-linger "$USER" 2>/dev/null; then
    say "linger:  enabled (timer runs even when logged out)"
  else
    say "NOTE:    could not enable linger without privileges. Run this once:"
    say "             sudo loginctl enable-linger $USER"
    say "         Until then the timer only runs while you are logged in."
  fi
}

uninstall_systemd() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
  systemctl --user disable --now "${LABEL}.timer" >/dev/null 2>&1
  rm -f "${dir}/${LABEL}.timer" "${dir}/${LABEL}.service"
  systemctl --user daemon-reload
  say "removed the systemd timer and service"
}

# ------------------------------------------------------------------- macos ---

install_launchd() {
  local plist="$HOME/Library/LaunchAgents/com.${LABEL}.plist"
  mkdir -p "$HOME/Library/LaunchAgents"

  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>            <string>com.${LABEL}</string>
    <key>ProgramArguments</key> <array><string>${SYNC}</string></array>
    <key>StartInterval</key>    <integer>21600</integer>
    <key>RunAtLoad</key>        <true/>
    <key>StandardOutPath</key>  <string>${HOME}/Library/Logs/${LABEL}.log</string>
    <key>StandardErrorPath</key><string>${HOME}/Library/Logs/${LABEL}.log</string>
</dict>
</plist>
EOF

  launchctl unload "$plist" >/dev/null 2>&1
  launchctl load "$plist" || fail "could not load the launch agent"
  say "installed: ${plist}"
  say "log:     ~/Library/Logs/${LABEL}.log"
}

uninstall_launchd() {
  local plist="$HOME/Library/LaunchAgents/com.${LABEL}.plist"
  launchctl unload "$plist" >/dev/null 2>&1
  rm -f "$plist"
  say "removed the launch agent"
}

# -------------------------------------------------------------------- main ---

if [ "$UNINSTALL" = 1 ]; then
  case "$(uname -s)" in
    Linux)  uninstall_systemd ;;
    Darwin) uninstall_launchd ;;
    *)      fail "unsupported platform: $(uname -s)" ;;
  esac
  exit 0
fi

echo "Installing the skills sync timer (every 6 hours)"
preflight

case "$(uname -s)" in
  Linux)
    systemctl --user --version >/dev/null 2>&1 || fail "systemd user instance unavailable; install a cron entry by hand instead"
    install_systemd
    ;;
  Darwin) install_launchd ;;
  *)      fail "unsupported platform: $(uname -s). Supported: Linux (systemd), macOS (launchd)." ;;
esac

echo
echo "Done. Running one sync now to prove it works:"
"$SYNC"

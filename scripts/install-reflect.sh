#!/usr/bin/env bash
# Install the timer that mines finished sessions for candidate rules.
#
# Run once per machine, from anywhere:
#     ~/.claude/scripts/install-reflect.sh
#
# Idempotent — running it again re-installs cleanly over the previous install.
# Uninstall with: ~/.claude/scripts/install-reflect.sh --uninstall
#
# Claude Code does not need to be running. The timer is an OS-level scheduler
# that launches `claude -p` headlessly; the machine only needs to be powered on,
# and Persistent=true covers the times it was not.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="${REPO}/scripts/reflect-batch.sh"
LOG="${REPO}/hooks/reflect.log"
LABEL="claude-reflect"

# Every 6 hours, 30 minutes before each sync slot (00:00/06:00/12:00/18:00).
#
# Six-hourly rather than daily because a pass with nothing pending never invokes
# the model — it greps the transcripts, finds no new lines and exits. Cost
# tracks session volume, not timer frequency, so the extra slots are close to
# free and a finished session waits ~6h to be mined instead of ~24h.
#
# The offset is a backstop, not the mechanism. A headless pass fires SessionEnd
# when it exits, which already kicks a sync — verified. The 30 minutes only
# guarantee the staged candidates reach the remote even if that hook does not
# fire.
HOURS="05,11,17,23"
MINUTE="30"
UNINSTALL=0
[ "${1:-}" = "--uninstall" ] && UNINSTALL=1

say()  { printf '  %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ -f "$RUNNER" ] || fail "reflect-batch.sh not found at ${RUNNER}"
chmod +x "$RUNNER"

preflight() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by reflect-batch.sh"
  command -v claude >/dev/null 2>&1 || fail "the claude CLI is not on PATH"
  say "runner:  ${RUNNER}"
  say "log:     ${LOG}"
  say "when:    ${HOURS}:${MINUTE} — every 6h, 30min before each sync slot"
  say "         and on next boot if the machine was off through one"
}

# ------------------------------------------------------------------- linux ---

install_systemd() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
  mkdir -p "$dir"

  # The timer has no login shell, so PATH may not include ~/.local/bin where
  # the claude CLI usually lives. Resolve it now rather than at fire time.
  local claude_dir; claude_dir="$(dirname "$(command -v claude)")"

  cat > "${dir}/${LABEL}.service" <<EOF
[Unit]
Description=Mine finished Claude Code sessions for candidate rules
Documentation=file://${REPO}/README.md

[Service]
Type=oneshot
Environment=PATH=${claude_dir}:/usr/local/bin:/usr/bin:/bin
ExecStart=/bin/sh -c '${RUNNER} >> ${LOG} 2>&1'
# One pass reads at most --limit sessions; well inside this, and a hung model
# call must not keep the next night's run from firing.
TimeoutStartSec=2400
EOF

  # OnCalendar + Persistent is the combination that survives the machine being
  # off: a run missed while powered down fires on next boot instead of waiting
  # for the following slot. Note systemd catches up with a SINGLE activation,
  # not one per missed day — which is right here, because the runner works from
  # a queue, so one pass after three days off still sees all three days.
  cat > "${dir}/${LABEL}.timer" <<EOF
[Unit]
Description=Reflect pass over unread session transcripts, every 6 hours

[Timer]
OnCalendar=*-*-* ${HOURS}:${MINUTE}:00
Persistent=true
OnBootSec=10min
RandomizedDelaySec=300
Unit=${LABEL}.service

[Install]
WantedBy=timers.target
EOF

  # Seed the stamp BEFORE enabling. Persistent=true means systemd compares the
  # last-elapse stamp against the schedule, and with no stamp at all it treats
  # the timer as infinitely overdue and fires the moment it is enabled — so
  # installing would kick off a live pass over the whole backlog as a side
  # effect. Writing the stamp with mtime=now makes the first fire the next
  # genuine slot. Catch-up after that works normally.
  local stampdir="${XDG_DATA_HOME:-$HOME/.local/share}/systemd/timers"
  mkdir -p "$stampdir"
  : > "${stampdir}/stamp-${LABEL}.timer"

  systemctl --user daemon-reload
  systemctl --user enable --now "${LABEL}.timer" >/dev/null 2>&1 || fail "could not enable the timer"
  say "installed: ${dir}/${LABEL}.timer"
  say "next fire: $(systemctl --user list-timers "${LABEL}.timer" --no-pager 2>/dev/null | awk 'NR==2{print $1, $2, $3}')"

  # Without lingering, user units stop at logout and do not start on boot until
  # you log in — which defeats "runs at 5am whether or not I am at the machine".
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

  # StartCalendarInterval is launchd's Persistent= equivalent: if the machine
  # was asleep or off at the scheduled time, the job runs once on wake. Several
  # slots need an ARRAY of dicts — a single dict with a comma in Hour is not
  # valid and silently never fires.
  local slots=""
  local h
  for h in ${HOURS//,/ }; do
    slots="${slots}        <dict><key>Hour</key><integer>${h}</integer><key>Minute</key><integer>${MINUTE}</integer></dict>
"
  done

  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>            <string>com.${LABEL}</string>
    <key>ProgramArguments</key> <array><string>${RUNNER}</string></array>
    <key>StartCalendarInterval</key>
    <array>
${slots}    </array>
    <key>StandardOutPath</key>  <string>${LOG}</string>
    <key>StandardErrorPath</key><string>${LOG}</string>
</dict>
</plist>
EOF

  launchctl unload "$plist" >/dev/null 2>&1
  launchctl load "$plist" || fail "could not load the launch agent"
  say "installed: ${plist}"
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

preflight
case "$(uname -s)" in
  Linux)  install_systemd ;;
  Darwin) install_launchd ;;
  *)      fail "unsupported platform: $(uname -s)" ;;
esac

printf '\n'
say "check it:     systemctl --user list-timers ${LABEL}.timer"
say "see the log:  tail -f ${LOG}"
say "what is due:  ${RUNNER} --status"
say "run it now:   ${RUNNER} --dry-run"

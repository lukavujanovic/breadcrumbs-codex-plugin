#!/usr/bin/env bash
# Breadcrumbs auto-log: snapshot repo state at the start of each user turn.
# Paired with log_on_stop.sh which compares this snapshot against the state at
# Stop time and posts a one-line summary to the project Coding Log if the repo
# changed during the turn.
#
# Inputs (stdin JSON, from Claude Code UserPromptSubmit hook):
#   { "session_id": "...", "cwd": "...", "hook_event_name": "UserPromptSubmit", "prompt": "..." }
#
# Always exits 0. Hook failures must never disrupt the user's session.

set +e

# Opt-out via env var.
[ -n "$BREADCRUMBS_AUTOLOG_DISABLED" ] && exit 0

INPUT=$(cat)
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$SID" ] && exit 0

# Resolve the git repo containing cwd. If not in a repo, no snapshot — Stop will
# see no state file and skip cleanly.
REPO=$(git -C "${CWD:-.}" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO" ] && exit 0

HEAD=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)

# DIRTY_HASH summarizes everything that would make the working tree look
# different from HEAD: the diff itself plus the list of new untracked files.
DIRTY=$(
  {
    git -C "$REPO" diff HEAD 2>/dev/null
    git -C "$REPO" ls-files --others --exclude-standard 2>/dev/null
  } | shasum -a 256 | awk '{print $1}'
)

STATE="${TMPDIR:-/tmp}/breadcrumbs-hook-${SID}.state"
{
  printf 'REPO=%s\n' "$REPO"
  printf 'HEAD=%s\n' "$HEAD"
  printf 'DIRTY_HASH=%s\n' "$DIRTY"
} > "$STATE"

# GC any state files older than 1 day (covers the case where a previous Stop
# hook didn't run — e.g. crash, kill -9 — and left a stale file behind).
find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'breadcrumbs-hook-*.state' -mtime +1 -delete 2>/dev/null

exit 0

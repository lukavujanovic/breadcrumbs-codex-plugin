#!/usr/bin/env bash
# Breadcrumbs auto-log: at end of each user turn, compare current repo state
# against the snapshot taken by snapshot_repo.sh. If the repo changed, post a
# one-line summary (file names + diff stat, no diff content) to the project
# Coding Log via the Breadcrumbs MCP server.
#
# Inputs (stdin JSON, from Claude Code Stop hook):
#   { "session_id": "...", "cwd": "...", "hook_event_name": "Stop" }
#
# Always exits 0. Hook failures must never disrupt the user's session.

set +e

[ -n "$BREADCRUMBS_AUTOLOG_DISABLED" ] && exit 0
[ -z "$BREADCRUMBS_MCP_TOKEN" ] && exit 0

INPUT=$(cat)
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SID" ] && exit 0

STATE="${TMPDIR:-/tmp}/breadcrumbs-hook-${SID}.state"
[ ! -s "$STATE" ] && exit 0

# Load REPO / HEAD / DIRTY_HASH set by snapshot_repo.sh.
# shellcheck disable=SC1090
. "$STATE"
[ -z "$REPO" ] && { rm -f "$STATE"; exit 0; }

# Repo could have been deleted mid-turn — check before running git.
if [ ! -d "$REPO/.git" ] && [ ! -f "$REPO/.git" ]; then
  rm -f "$STATE"
  exit 0
fi

NEW_HEAD=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)
NEW_DIRTY=$(
  {
    git -C "$REPO" diff HEAD 2>/dev/null
    git -C "$REPO" ls-files --others --exclude-standard 2>/dev/null
  } | shasum -a 256 | awk '{print $1}'
)

if [ "$NEW_HEAD" = "$HEAD" ] && [ "$NEW_DIRTY" = "$DIRTY_HASH" ]; then
  rm -f "$STATE"
  exit 0
fi

REPO_NAME=$(basename "$REPO")
SECTIONS=()

if [ "$NEW_HEAD" != "$HEAD" ]; then
  COMMITS=$(git -C "$REPO" log --oneline "$HEAD..$NEW_HEAD" 2>/dev/null | head -10)
  [ -n "$COMMITS" ] && SECTIONS+=("New commits:"$'\n'"$COMMITS")
fi

STAT=$(git -C "$REPO" diff --stat HEAD 2>/dev/null | head -20)
[ -n "$STAT" ] && SECTIONS+=("Working tree:"$'\n'"$STAT")

UNTRACKED=$(git -C "$REPO" ls-files --others --exclude-standard 2>/dev/null | head -10)
if [ -n "$UNTRACKED" ]; then
  COUNT=$(printf '%s\n' "$UNTRACKED" | wc -l | tr -d ' ')
  SECTIONS+=("Untracked (${COUNT}):"$'\n'"$UNTRACKED")
fi

if [ ${#SECTIONS[@]} -eq 0 ]; then
  rm -f "$STATE"
  exit 0
fi

BODY=$(printf '%s\n\n' "${SECTIONS[@]}")
MESSAGE=$(printf 'Touched %s\n\n```\n%s```' "$REPO_NAME" "$BODY")

"${CLAUDE_PLUGIN_ROOT}/hooks/post_log.sh" "$MESSAGE" "auto-log,${REPO_NAME}"
rm -f "$STATE"
exit 0

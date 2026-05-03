#!/usr/bin/env bash
# Breadcrumbs auto-log: invoke the log_activity MCP tool via a stateless
# JSON-RPC POST to the Breadcrumbs MCP endpoint.
#
# Args:
#   $1  message  — markdown content for the Coding Log entry
#   $2  tags_csv — comma-separated tags (e.g. "auto-log,my-repo")
#
# Requires: $BREADCRUMBS_MCP_TOKEN in the environment.
# Always exits 0.

set +e

MESSAGE="$1"
TAGS_CSV="$2"

[ -z "$BREADCRUMBS_MCP_TOKEN" ] && exit 0
[ -z "$MESSAGE" ] && exit 0

TAGS=$(printf '%s' "$TAGS_CSV" | jq -R 'split(",") | map(select(length>0))' 2>/dev/null)
[ -z "$TAGS" ] && TAGS='[]'

PAYLOAD=$(jq -n --arg m "$MESSAGE" --argjson t "$TAGS" '{
  jsonrpc: "2.0",
  id: 1,
  method: "tools/call",
  params: { name: "log_activity", arguments: { message: $m, tags: $t } }
}' 2>/dev/null)
[ -z "$PAYLOAD" ] && exit 0

curl -sS --max-time 5 -o /dev/null \
  -X POST "${BREADCRUMBS_MCP_URL:-https://breadcrumbs.dev/mcp}" \
  -H "Authorization: Bearer ${BREADCRUMBS_MCP_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  --data "$PAYLOAD"

exit 0

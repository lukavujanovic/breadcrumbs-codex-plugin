# Breadcrumbs Codex Plugin

Install Breadcrumbs in Codex with a bundled MCP server configuration and a feature lifecycle skill.

## What This Includes

- `plugins/breadcrumbs-mcp/.codex-plugin/plugin.json`: Codex plugin metadata.
- `plugins/breadcrumbs-mcp/.mcp.json`: MCP configuration for `https://breadcrumbs.dev/mcp`.
- `plugins/breadcrumbs-mcp/skills/feature-lifecycle/SKILL.md`: instructions for agents starting, updating, and finishing feature work.
- `.agents/plugins/marketplace.json`: repo marketplace catalog so Codex can discover the plugin.

No API keys or bearer tokens are stored in this repo. The MCP config only references an environment variable name.

## Install

Set your Breadcrumbs project API key in your macOS login environment:

```zsh
launchctl setenv BREADCRUMBS_MCP_TOKEN "bc_<your_project_api_key>"
```

Add this marketplace to Codex:

```zsh
codex plugin marketplace add xie-andy/breadcrumbs-codex-plugin
```

Then restart Codex and enable `Breadcrumbs MCP` from the plugin UI.

## Direct MCP Install

If you only want the MCP tools and do not need the feature lifecycle skill:

```zsh
launchctl setenv BREADCRUMBS_MCP_TOKEN "bc_<your_project_api_key>"

codex mcp add breadcrumbs-mcp \
  --url https://breadcrumbs.dev/mcp \
  --bearer-token-env-var BREADCRUMBS_MCP_TOKEN
```

## Verify

After installing, ask Codex:

```text
Use Breadcrumbs to show the project overview.
```

Codex should be able to call Breadcrumbs MCP tools such as `get_project_overview`, `get_kanban_board`, `update_card`, `add_note`, `write_documentation`, and `log_activity`.

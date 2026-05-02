# Breadcrumbs MCP Plugin

This plugin connects Codex to a Breadcrumbs project through the Breadcrumbs MCP server and adds a feature lifecycle skill for keeping the board, notes, docs, and Coding Log current.

## MCP Configuration

The bundled `.mcp.json` targets the hosted Breadcrumbs MCP endpoint:

```json
{
  "mcpServers": {
    "breadcrumbs-mcp": {
      "url": "https://breadcrumbs.dev/mcp",
      "bearer_token_env_var": "BREADCRUMBS_MCP_TOKEN"
    }
  }
}
```

No bearer token is stored in this plugin. Codex reads the token from `BREADCRUMBS_MCP_TOKEN` in the user's environment.

## Included Skill

`feature-lifecycle` tells agents how to use Breadcrumbs when starting, continuing, and ending feature work:

- read project overview and kanban state before starting;
- move the relevant card to `In Progress`;
- log meaningful milestones and blockers;
- attach durable card notes;
- write project documentation for setup, API, architecture, and operational knowledge;
- move cards to `Review` or `Done` only after appropriate verification.

## Expected Tools

The plugin expects the Breadcrumbs MCP server to expose:

- `get_project_overview`
- `get_kanban_board`
- `update_card`
- `add_note`
- `write_documentation`
- `log_activity`

# Breadcrumbs Codex Plugin

Breadcrumbs MCP connects Codex to a Breadcrumbs project so agents can use the project board, Coding Log, card notes, and documentation while working on features.

## What It Provides

- A Codex plugin manifest for `breadcrumbs-mcp`.
- A Streamable HTTP MCP configuration for `https://breadcrumbs.dev/mcp`.
- A `feature-lifecycle` skill that guides agents through starting, updating, and finishing feature work in Breadcrumbs.
- A Codex marketplace catalog at `.agents/plugins/marketplace.json`.

## Repository Layout

```text
.agents/plugins/marketplace.json
plugins/breadcrumbs-mcp/.codex-plugin/plugin.json
plugins/breadcrumbs-mcp/.mcp.json
plugins/breadcrumbs-mcp/README.md
plugins/breadcrumbs-mcp/skills/feature-lifecycle/SKILL.md
```

## Security

This repository does not include API keys, bearer tokens, `.env` files, or user project data.

The bundled MCP config references the environment variable `BREADCRUMBS_MCP_TOKEN`; the token value is supplied by the user's local Codex environment.

## MCP Tools

The Breadcrumbs MCP server exposes tools for:

- reading project overview and documentation summaries;
- reading the full kanban board;
- moving or editing kanban cards;
- attaching notes to cards;
- writing project documentation;
- logging activity to the project Coding Log.

## Agent Workflow

The included skill asks agents to:

- read Breadcrumbs context before starting feature work;
- move the active card to `In Progress`;
- log meaningful milestones, blockers, and verification results;
- attach durable notes and documentation when useful;
- move cards to `Review` or `Done` only after appropriate verification.

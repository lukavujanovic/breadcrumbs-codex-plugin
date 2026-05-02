---
name: feature-lifecycle
description: Use when starting, continuing, or finishing feature work in a Breadcrumbs-tracked project. Guides Codex to read Breadcrumbs context, update kanban cards, log progress, attach card notes, and write durable documentation through the Breadcrumbs MCP server.
---

# Breadcrumbs Feature Lifecycle

Use this skill whenever feature work is being planned, started, continued, paused, reviewed, or completed in a project connected to Breadcrumbs MCP.

Breadcrumbs is the source of truth for project state. Prefer the Breadcrumbs MCP tools over direct database edits, local notes, or ad hoc status messages when recording project progress.

## Available MCP Tools

Use the `breadcrumbs-mcp` server tools when available:

- `get_project_overview`: read project name, description, column counts, and documentation summary.
- `get_kanban_board`: read all columns and cards, including card IDs.
- `update_card`: move a card to a column or update its title/description.
- `add_note`: attach a durable note to a specific kanban card.
- `write_documentation`: create or update a project documentation page by title.
- `log_activity`: append a real-time entry to the project's Coding Log.

If these tools are not available, tell the user that Breadcrumbs MCP is not loaded and continue with normal local work. Do not invent card IDs or pretend to update Breadcrumbs.

## Feature Start Flow

At the start of a feature, establish project context before editing code:

1. Call `get_project_overview` to understand the project and current board shape.
2. Call `get_kanban_board` to find the relevant card.
3. If the user named a card, match by exact title first, then obvious case-insensitive title match.
4. If multiple cards could match, ask the user which card to use.
5. If no card exists and the user did not ask you to create one, continue without a card and log only if the user confirms where to track the work.
6. Move the selected card to `In Progress` with `update_card` unless it is already there or the user asks for another status.
7. Call `log_activity` with a concise start entry describing the feature and intended outcome.
8. Add a card note with `add_note` when there is useful feature-specific context, acceptance criteria, a risk, or an implementation decision worth keeping with the card.

Start log entries should be short and concrete. Good examples:

```text
Started feature: add streamable HTTP MCP support for Codex. Plan is to keep SSE compatibility and add /mcp for modern clients.
```

```text
Started card "Invite flow polish". First pass will cover API validation, UI empty states, and invite notification behavior.
```

## During Feature Work

While implementing, keep Breadcrumbs updated only when something meaningful changes:

- Use `log_activity` for milestones, decisions, blockers, and verification results.
- Use `add_note` for card-specific details that should stay attached to the work item.
- Use `write_documentation` for durable project knowledge, setup instructions, API contracts, architecture notes, or feature behavior that future agents/humans should reuse.
- Use `update_card` if the scope/title/description changes materially.

Do not spam the Coding Log with every file read or tiny edit. Breadcrumbs updates should help someone reconstruct the work later.

## Feature End Flow

When a feature is done or the user asks you to wrap up:

1. Run the relevant checks first when feasible: tests, build, lint, local endpoint probes, or manual verification.
2. Call `log_activity` with the final result, including what passed and any known caveats.
3. Add a card note when the final state includes important caveats, follow-up work, deployment steps, or user-facing behavior.
4. Write or update documentation if the feature changed setup, APIs, architecture, operational steps, or MCP/client configuration.
5. Move the card with `update_card`:
   - Move to `Done` when implementation and verification are complete.
   - Move to `Review` when code is ready but needs human review, deployment, or approval.
   - Leave in `In Progress` when blocked or incomplete, and log the blocker.
6. Read back `get_kanban_board` after moving a card to confirm the final board state.

End log entries should include verification, not just intent. Good examples:

```text
Finished streamable HTTP MCP support. Verified local initialize and tools/list against /mcp; existing SSE endpoint remains available.
```

```text
Paused invite flow polish. API validation is complete, but email preview still needs manual browser QA.
```

## Status Mapping

Use the project's existing column names exactly as returned by `get_kanban_board`. Common mappings:

- Starting active implementation: `In Progress`
- Ready for human/code review: `Review`
- Fully implemented and verified: `Done`
- Not started or intentionally deferred: `Backlog`

If the board uses different names, choose the closest matching column and mention the choice in `log_activity`.

## Documentation Guidance

Use `write_documentation` when the work creates knowledge that should outlive the current conversation:

- New setup or environment variables.
- API endpoints, MCP transports, auth flows, or client configuration.
- Deployment or migration steps.
- Non-obvious technical decisions.
- Debugging notes that future agents are likely to need.

Keep documentation pages focused. Prefer titles like:

```text
MCP Client Setup
Feature Lifecycle Workflow
Deployment Notes
```

## Safety Rules

- Never move an unrelated card.
- Never mark a card `Done` before verification unless the user explicitly requests it.
- Never put secrets in logs, notes, or documentation.
- Do not overwrite documentation with narrower content; update it while preserving useful existing context.
- If Breadcrumbs MCP calls fail, report the failure and continue locally rather than repeatedly retrying.

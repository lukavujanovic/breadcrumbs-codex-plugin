---
name: feature-lifecycle
description: Use when starting, continuing, pausing, reviewing, or finishing feature work in any project where Breadcrumbs MCP is available for project state. Guides an AI agent to use Breadcrumbs as the source of truth by reading project state, creating or updating kanban cards, moving cards through workflow columns, logging tagged activity, adding card notes, and safely reading, writing, or deleting durable project documentation.
---

# Breadcrumbs Feature Lifecycle

Use Breadcrumbs MCP as the project control room for tracked feature work. Keep local implementation, kanban state, coding log entries, card notes, and project documentation aligned while you work.

Core rule: no ghost work. Before editing code for a feature, make sure the work is represented by a Breadcrumbs kanban card. If a relevant card does not exist, create one.

## Available MCP Tools

Use the Breadcrumbs MCP tools when they are available:

- `get_project_overview`: Get project name, description, board column counts, and documentation page titles.
- `get_kanban_board`: Get full columns and cards, including card IDs, descriptions, and assignees.
- `create_card`: Create a kanban card. Use this when no relevant card exists. It defaults to `Backlog` or the leftmost column when `column_name` is omitted.
- `update_card`: Move a card by `column_name`, or update its `title` and `description`.
- `add_note`: Attach durable decisions, blockers, caveats, or follow-up details to a specific card.
- `log_activity`: Add a real-time Coding Log entry. Include useful `tags`, such as `["backend", "mcp"]` or `["frontend", "auth"]`.
- `read_documentation`: Read a documentation page by title before making non-destructive edits.
- `write_documentation`: Create or update a documentation page by title.
- `delete_documentation`: Delete an obsolete documentation page by title. Use only when cleanup is explicitly requested or clearly part of the task.

If the MCP tools are unavailable or fail, tell the user what could not be synced, then continue locally when practical. Do not invent card IDs, documentation contents, or successful Breadcrumbs updates.

## Start Flow

At the start of feature work, build Breadcrumbs context before code changes:

1. Call `get_project_overview` to learn the project, available columns, and documentation pages.
2. Call `get_kanban_board` to inspect existing cards and collect card IDs.
3. Match the requested work to an existing card by exact title, clear case-insensitive title match, or obvious description match.
4. If multiple cards reasonably match, ask the user which card to use.
5. If no relevant card exists, call `create_card` with a concise title, useful description, and the best starting column.
6. Move the target card to `In Progress` or the closest active-work column with `update_card`, unless the user requested a different state.
7. Call `log_activity` with a kickoff entry and relevant tags.
8. Use `add_note` for acceptance criteria, notable constraints, or initial technical decisions that should stay attached to the card.

Keep kickoff logs short and concrete:

```text
Started feature: add streamable HTTP MCP support. Plan is to keep SSE compatibility and add /mcp for modern clients.
```

## Continue Flow

When continuing existing work:

1. Call `get_project_overview` and `get_kanban_board`.
2. Locate the current card. If the user names a card, prefer exact or obvious title matches.
3. Move the card to an active column if work is resuming from `Backlog`, `Review`, or a paused state.
4. Read relevant documentation pages with `read_documentation` when setup, API behavior, architecture, or prior decisions matter.
5. Log the restart only when the resumed work is substantial or changes the current plan.

## During Work

Sync Breadcrumbs on meaningful state changes, not every file read or edit.

- Use `log_activity` for milestones, verification results, and high-signal progress updates. Always include relevant tags.
- Use `add_note` for card-specific decisions, blockers, risk, technical debt, handoff notes, or review caveats.
- Use `update_card` if the title, description, scope, or workflow state changes materially.
- Use `create_card` for newly discovered work that should be tracked separately instead of hiding scope creep inside the current card.
- Use `read_documentation` before relying on or editing an existing documentation page.

Keep `log_activity` focused on the project timeline. Keep `add_note` focused on durable card context.

## Documentation Flow

Use Breadcrumbs documentation for knowledge that should outlive the current thread: setup steps, environment variables, API contracts, MCP/client configuration, deployment notes, migrations, architecture decisions, and debugging procedures.

Follow this non-destructive edit protocol:

1. Call `get_project_overview` to discover existing documentation titles.
2. If the page may already exist, call `read_documentation` first.
3. Merge or append the new information while preserving useful existing content.
4. Call `write_documentation` with the complete updated page content.
5. Use `delete_documentation` only for obsolete or duplicate pages when deletion is intentional.

Never blindly overwrite an existing page with narrower content. Never store secrets, API keys, raw tokens, or private credentials in documentation.

Prefer focused page titles such as:

```text
MCP Server
MCP Client Setup
Feature Lifecycle Workflow
Database & Migrations
Deployment
```

## Pause And Blocker Flow

When work pauses, blocks, or cannot be completed:

1. Run any checks that are still useful for the partial state.
2. Call `log_activity` with what is complete, what is blocked, and what remains.
3. Call `add_note` with the blocker, reproduction details, or handoff instructions.
4. Move the card to the closest paused, blocked, or active column available on the board. If no such column exists, leave it in `In Progress`.
5. Do not move the card to `Done`.

## Review Flow

When code is ready for human review or PR review:

1. Run the relevant checks first when feasible.
2. Call `log_activity` with the review-ready summary, checks run, and known caveats.
3. Add a card note for review focus areas, manual QA steps, deployment warnings, or unresolved tradeoffs.
4. Move the card to `Review` or the closest equivalent column.
5. Call `get_kanban_board` to confirm the final card state.

## Finish Flow

When a feature is complete:

1. Verify with the relevant tests, build, lint, local endpoint probes, or manual checks.
2. Update documentation if setup, APIs, architecture, operations, or MCP/client behavior changed.
3. Call `log_activity` with the final result, verification performed, and any caveats.
4. Add a final card note only when there is durable handoff context.
5. Move the card to `Done` only when implementation and verification are complete. Move it to `Review` if human QA, deployment, or approval remains.
6. Call `get_kanban_board` to confirm the card landed in the intended final column.

Completion logs should include evidence:

```text
Finished streamable HTTP MCP support. Verified initialize and tools/list against /mcp; existing SSE endpoint remains available.
```

## Status Mapping

Use column names exactly as returned by `get_kanban_board`. Map intent to the closest available column:

- Active implementation: `In Progress`
- Ready for review or QA: `Review`
- Fully implemented and verified: `Done`
- Not started or deferred: `Backlog`

If the board uses different names, choose the closest semantic match and mention the mapping in `log_activity`.

## Safety Rules

- Never move, edit, or annotate an unrelated card.
- Never mark work `Done` before verification unless the user explicitly requests that state.
- Never store secrets in `log_activity`, `add_note`, or documentation.
- Do not repeatedly retry failing MCP calls.
- Do not delete documentation unless deletion is explicitly requested or clearly correct cleanup.
- Keep Breadcrumbs updates useful for reconstructing the work later.

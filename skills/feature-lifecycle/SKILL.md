---
name: feature-lifecycle
description: Use when starting, continuing, pausing, reviewing, or finishing feature work in any project where Breadcrumbs MCP is available for project state. Guides an AI agent to use Breadcrumbs as the source of truth by reading project state, creating or updating kanban cards, creating and updating structured card plans and verification checklists, moving cards through workflow columns, logging tagged activity, adding card notes, and safely reading, writing, or deleting durable project documentation.
---

# Breadcrumbs Feature Lifecycle

Use Breadcrumbs MCP as the project control room for tracked feature work. Keep local implementation, kanban state, card plans, verification checklists, coding log entries, card notes, and project documentation aligned while you work.

Core rule: no ghost work. Before editing code for a feature, make sure the work is represented by a Breadcrumbs kanban card. If a relevant card does not exist, create one.

Core planning rule: before beginning implementation on a card, create or update the card's structured plan with the concrete steps you intend to execute. Before marking work complete, create or update the card's verification checklist and mark checks with evidence.

## Available MCP Tools

Use the Breadcrumbs MCP tools when they are available:

- `get_project_overview`: Get project name, description, board column counts, and documentation page titles.
- `get_kanban_board`: Get full columns and cards, including card IDs, descriptions, and assignees.
- `get_card_details`: Get full details for a kanban card, including notes, plan, verification, and version fields.
- `create_card`: Create a kanban card. Use this when no relevant card exists. It defaults to `Backlog` or the leftmost column when `column_name` is omitted.
- `update_card`: Move a card by `column_name`, or update its `title` and `description`.
- `set_card_plan`: Replace a card's structured plan. Step IDs are generated for steps without IDs; missing statuses default to `todo`.
- `update_card_plan_steps`: Bulk update plan step statuses by stable step ID. No partial update is applied if any step ID is unknown.
- `set_card_verification`: Replace a card's structured verification checklist. Check IDs are generated for checks without IDs; missing statuses default to `pending`.
- `update_card_verification_checks`: Bulk update verification check statuses by stable check ID. No partial update is applied if any check ID is unknown.
- `add_note`: Attach durable decisions, blockers, caveats, or follow-up details to a specific card.
- `log_activity`: Add a real-time Coding Log entry. Include useful `tags`, such as `["backend", "mcp"]` or `["frontend", "auth"]`.
- `read_documentation`: Read a documentation page by title before making non-destructive edits.
- `write_documentation`: Create or update a documentation page by title.
- `delete_documentation`: Delete an obsolete documentation page by title. Use only when cleanup is explicitly requested or clearly part of the task.

If the MCP tools are unavailable or fail, tell the user what could not be synced, then continue locally when practical. Do not invent card IDs, documentation contents, plan IDs, verification IDs, or successful Breadcrumbs updates.

## Plan And Verification Schema

Card plans use ordered steps:

```json
{
  "steps": [
    {
      "title": "Implement backend endpoint",
      "detail": "Add request validation and persistence.",
      "status": "todo",
      "note": "Optional progress note"
    }
  ]
}
```

Valid plan step statuses:

- `todo`: Not started.
- `doing`: Currently in progress.
- `done`: Completed.
- `blocked`: Blocked or needs outside input.

Verification uses ordered checks:

```json
{
  "checks": [
    {
      "title": "Run backend tests",
      "detail": "Run the focused pytest suite and then full backend tests.",
      "status": "pending",
      "evidence": "Optional command output or summary"
    }
  ]
}
```

Valid verification statuses:

- `pending`: Not checked yet.
- `passed`: Verified successfully.
- `failed`: Verification failed.
- `skipped`: Intentionally not run, with evidence explaining why.

Prefer concise titles and put command names, caveats, or expected evidence in `detail`.

## Start Flow

At the start of feature work, build Breadcrumbs context before code changes:

1. Call `get_project_overview` to learn the project, available columns, and documentation pages.
2. Call `get_kanban_board` to inspect existing cards and collect card IDs.
3. Match the requested work to an existing card by exact title, clear case-insensitive title match, or obvious description match.
4. If multiple cards reasonably match, ask the user which card to use.
5. If no relevant card exists, call `create_card` with a concise title, useful description, and the best starting column.
6. Move the target card to `In Progress` or the closest active-work column with `update_card`, unless the user requested a different state.
7. Call `get_card_details` for the target card.
8. Call `set_card_plan` with a concrete implementation plan before editing code.
9. Call `set_card_verification` with the checks you expect to run before completion.
10. Call `log_activity` with a kickoff entry and relevant tags.
11. Use `add_note` for acceptance criteria, notable constraints, or initial technical decisions that should stay attached to the card.

Keep kickoff logs short and concrete:

```text
Started feature: add streamable HTTP MCP support. Plan and verification checklist are attached to the card.
```

## Planning Flow

Use `set_card_plan` whenever you begin substantial implementation work or materially change the approach.

Good plan steps are concrete and verifiable:

```json
{
  "card_id": "card-uuid",
  "steps": [
    {
      "title": "Add database migration",
      "detail": "Create nullable fields so existing cards remain valid."
    },
    {
      "title": "Expose API fields",
      "detail": "Return the new fields in card payloads and add update endpoints."
    },
    {
      "title": "Update frontend rendering",
      "detail": "Show progress badges and drawer sections."
    }
  ]
}
```

During work, update plan progress with `update_card_plan_steps`, preferably in bulk:

```json
{
  "card_id": "card-uuid",
  "updates": [
    {
      "step_id": "generated-step-id",
      "status": "done",
      "note": "Migration added and compile-checked."
    },
    {
      "step_id": "next-step-id",
      "status": "doing"
    }
  ]
}
```

Rules:

- Use stable `step_id` values returned by `set_card_plan` or `get_card_details`.
- Do not update by list position.
- If a step is missing, call `get_card_details` and reconcile before retrying.
- Keep only one or two steps marked `doing` unless parallel work is truly happening.
- Mark blocked work as `blocked` and explain the blocker in `note`.

## Verification Flow

Use `set_card_verification` early, ideally before implementation starts, so the expected proof is visible on the card.

Example:

```json
{
  "card_id": "card-uuid",
  "checks": [
    {
      "title": "Frontend build",
      "detail": "Run npm run build."
    },
    {
      "title": "Backend tests",
      "detail": "Run docker compose run --rm backend python -m pytest."
    },
    {
      "title": "Manual smoke test",
      "detail": "Exercise the updated UI or MCP flow locally."
    }
  ]
}
```

After running checks, update results with `update_card_verification_checks`, preferably in bulk:

```json
{
  "card_id": "card-uuid",
  "updates": [
    {
      "check_id": "generated-check-id",
      "status": "passed",
      "evidence": "npm run build passed."
    },
    {
      "check_id": "another-check-id",
      "status": "failed",
      "evidence": "pytest failed in test_x with assertion error."
    }
  ]
}
```

Rules:

- Use `passed` only when the check actually succeeded.
- Use `failed` when a check was run and failed.
- Use `skipped` only when not running the check is intentional; include the reason in `evidence`.
- Do not mark a card `Done` while verification has failed or pending checks, unless the user explicitly overrides.
- If verification cannot be run because of environment limitations, mark the relevant check `skipped` with evidence and move the card to `Review`, not `Done`, unless the user says otherwise.

## Continue Flow

When continuing existing work:

1. Call `get_project_overview` and `get_kanban_board`.
2. Locate the current card. If the user names a card, prefer exact or obvious title matches.
3. Call `get_card_details` to inspect the existing plan, verification checklist, notes, and versions.
4. Move the card to an active column if work is resuming from `Backlog`, `Review`, or a paused state.
5. If no plan exists and implementation work remains, call `set_card_plan`.
6. If no verification checklist exists and verification will be needed, call `set_card_verification`.
7. Mark the next active plan step as `doing` with `update_card_plan_steps`.
8. Read relevant documentation pages with `read_documentation` when setup, API behavior, architecture, or prior decisions matter.
9. Log the restart only when the resumed work is substantial or changes the current plan.

## During Work

Sync Breadcrumbs on meaningful state changes, not every file read or edit.

- Use `update_card_plan_steps` when a step starts, completes, or becomes blocked.
- Use `update_card_verification_checks` when checks are run or intentionally skipped.
- Use `log_activity` for milestones, verification summaries, and high-signal progress updates. Always include relevant tags.
- Use `add_note` for durable decisions, blockers, risk, technical debt, handoff notes, or review caveats.
- Use `update_card` if the title, description, scope, or workflow state changes materially.
- Use `create_card` for newly discovered work that should be tracked separately instead of hiding scope creep inside the current card.
- Use `read_documentation` before relying on or editing an existing documentation page.

Keep `log_activity` focused on the project timeline. Keep `add_note` focused on durable card context. Keep plan step notes short and tied to that step.

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
2. Update the relevant plan step to `blocked` or leave completed steps as `done`.
3. Update verification checks that were run; mark blocked or unrunnable checks as `failed` or `skipped` with evidence, as appropriate.
4. Call `log_activity` with what is complete, what is blocked, and what remains.
5. Call `add_note` with the blocker, reproduction details, or handoff instructions.
6. Move the card to the closest paused, blocked, or active column available on the board. If no such column exists, leave it in `In Progress`.
7. Do not move the card to `Done`.

## Review Flow

When code is ready for human review or PR review:

1. Run the relevant checks first when feasible.
2. Mark all completed plan steps as `done`; leave unresolved work as `todo`, `doing`, or `blocked`.
3. Update verification checks with `passed`, `failed`, or `skipped` and evidence.
4. Call `log_activity` with the review-ready summary, checks run, and known caveats.
5. Add a card note for review focus areas, manual QA steps, deployment warnings, or unresolved tradeoffs.
6. Move the card to `Review` or the closest equivalent column.
7. Call `get_kanban_board` to confirm the final card state.

Use `Review` when human QA, deployment, approval, or failed/skipped verification remains.

## Finish Flow

When a feature is complete:

1. Verify with the relevant tests, build, lint, local endpoint probes, or manual checks.
2. Mark every completed plan step as `done` with `update_card_plan_steps`.
3. Mark every verification check as `passed` or `skipped` with evidence. Avoid `skipped` unless there is a clear reason.
4. Update documentation if setup, APIs, architecture, operations, or MCP/client behavior changed.
5. Call `log_activity` with the final result, verification performed, and any caveats.
6. Add a final card note only when there is durable handoff context.
7. Move the card to `Done` only when implementation is complete and verification is acceptable. Move it to `Review` if human QA, deployment, or approval remains.
8. Call `get_kanban_board` to confirm the card landed in the intended final column.

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
- Never invent plan step IDs or verification check IDs; use IDs returned by `set_card_plan`, `set_card_verification`, or `get_card_details`.
- Never update plan or verification by list position.
- Never partially retry a failed bulk update without first checking whether anything changed.
- Never store secrets in `log_activity`, `add_note`, plan notes, verification evidence, or documentation.
- Do not repeatedly retry failing MCP calls.
- Do not delete documentation unless deletion is explicitly requested or clearly correct cleanup.
- Keep Breadcrumbs updates useful for reconstructing the work later.

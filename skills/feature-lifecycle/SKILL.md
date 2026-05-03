---
name: feature-lifecycle
description: Use when starting, continuing, pausing, reviewing, deleting, or finishing feature work in any project where Breadcrumbs MCP is available for project state. Guides an AI agent to link the local repository to a Breadcrumbs project through .breadcrumbs/project.json, use user-scoped MCP authentication, pass explicit project_id values to project-scoped tools, and keep kanban cards, structured plans, verification checklists, unified notes, activity logs, and durable project documentation aligned.
---

# Breadcrumbs Feature Lifecycle

Use Breadcrumbs MCP as the project control room for tracked feature work. Keep local implementation, kanban state, card plans, verification checklists, unified notes, coding log entries, and project documentation aligned while you work.

Core rule: no ghost work. Before editing code for a feature, make sure the work is represented by a Breadcrumbs kanban card. If a relevant card does not exist, create one.

Core planning rule: before beginning implementation on a card, create or update the card's structured plan with the concrete steps you intend to execute. Before marking work complete, create or update the card's verification checklist and mark checks with evidence.

Core notes rule: Breadcrumbs uses one unified notes model. Project notes and card-attached notes are the same resource type. A card note is a note associated with a `card_id`; a project note has no `card_id`. Use note CRUD tools for all note lifecycle work. Use `add_note` only as a compatibility shortcut for creating a card-attached note.

Core auth rule: Breadcrumbs MCP authentication is user-scoped. A `bcu_...` API key identifies the user. It does not select a project. Never use, request, store, write, or infer project-scoped MCP keys. Never put API keys, tokens, passwords, or other secrets in repository files.

Core project-linking rule: project selection comes from `.breadcrumbs/project.json` in the local repository. Every project-scoped Breadcrumbs MCP call must include the `project_id` from that file. If the file is missing, list accessible projects, ask the user whether to link this repository to an existing project or create a new one, then write `.breadcrumbs/project.json` after the user chooses.

## Repo-Local Project Config

The canonical local config path is:

```text
.breadcrumbs/project.json
```

The file is non-secret project metadata. It must be safe to commit unless the user prefers to keep local workspace metadata ignored.

Expected shape:

```json
{
  "project_id": "project-uuid",
  "project_name": "Optional display name",
  "app_url": "https://breadcrumbs.dev"
}
```

Rules:

- `project_id` is required and must be used in every project-scoped MCP call.
- `project_name` is optional display metadata. Do not rely on it for identity.
- `app_url` is optional display/setup metadata.
- The file must never contain API keys, bearer tokens, Edstem tokens, passwords, cookies, private credentials, or other secrets.
- If `.breadcrumbs/` does not exist and a project is selected or created, create the folder and then write `project.json`.
- If the file exists but has invalid JSON, a missing `project_id`, or an inaccessible project, ask the user before overwriting it.
- If the current repository clearly maps to a different project than the file says, stop and ask the user to confirm before changing the file.

## Project Resolution Flow

Before calling project-scoped Breadcrumbs tools:

1. Look for `.breadcrumbs/project.json` from the current repository root.
2. If present, parse it and extract `project_id`.
3. Use that `project_id` in all project-scoped MCP calls.
4. If missing, call `list_projects` to show projects the authenticated user can access.
5. Ask the user whether to link this repository to an existing project or create a new project.
6. If the user chooses an existing project, write `.breadcrumbs/project.json` with that project's UUID and name.
7. If the user chooses a new project, call `create_project`, then write `.breadcrumbs/project.json` with the returned project UUID and name.
8. After writing the file, continue using that UUID for all future project-scoped calls in this repository.

Do not create a new Breadcrumbs project silently when accessible projects already exist unless the user's request clearly asks for a new project.

## Available MCP Tools

Use the Breadcrumbs MCP tools when they are available:

Project discovery tools:

- `list_projects`: List projects the authenticated user can access, including project IDs, names, descriptions, and member roles. Use this when `.breadcrumbs/project.json` is missing, invalid, or points to an inaccessible project.
- `create_project`: Create a new project owned by the authenticated user. Use only after the user chooses to create a new project, or when the request clearly requires one.

Project-scoped tools:

- `get_project_overview`: Get project name, description, board column counts, and documentation page titles.
- `get_kanban_board`: Get full columns and cards, including card IDs, descriptions, and assignees.
- `get_card_details`: Get full details for a kanban card, including notes, plan, verification, and version fields.
- `create_card`: Create a kanban card. Use this when no relevant card exists. It defaults to `Backlog` or the leftmost column when `column_name` is omitted.
- `update_card`: Move a card by `column_name`, or update its `title` and `description`.
- `delete_card`: Delete a kanban card when deletion is explicitly requested or clearly correct cleanup.
- `set_card_plan`: Replace a card's structured plan. Step IDs are generated for steps without IDs; missing statuses default to `todo`.
- `update_card_plan_steps`: Bulk update plan step statuses by stable step ID. No partial update is applied if any step ID is unknown.
- `set_card_verification`: Replace a card's structured verification checklist. Check IDs are generated for checks without IDs; missing statuses default to `pending`.
- `update_card_verification_checks`: Bulk update verification check statuses by stable check ID. No partial update is applied if any check ID is unknown.
- `list_notes`: List unified notes for a project. Use filters when available to narrow to project notes, card-attached notes, or a specific `card_id`.
- `get_note`: Read one unified note by ID.
- `create_note`: Create a unified note. Include `card_id` to attach it to a card; omit `card_id` for a standalone project note.
- `update_note`: Update a unified note's title, content, or card association when supported.
- `delete_note`: Delete a unified note when deletion is explicitly requested or clearly correct cleanup.
- `add_note`: Compatibility shortcut for creating a card-attached note. Prefer `create_note` for new workflows.
- `log_activity`: Add a real-time Coding Log entry. Include useful `tags`, such as `['backend', 'mcp']` or `['frontend', 'notes']`.
- `read_documentation`: Read a documentation page by title before making non-destructive edits.
- `write_documentation`: Create or update a documentation page by title.
- `delete_documentation`: Delete an obsolete documentation page by title. Use only when cleanup is explicitly requested or clearly part of the task.

Every project-scoped tool call must include the resolved `project_id`. If a tool returns a missing-project, nonexistent-project, or insufficient-access error, do not guess a replacement UUID. Re-run the Project Resolution Flow or ask the user.

If the MCP tools are unavailable or fail, tell the user what could not be synced, then continue locally when practical. Do not invent project IDs, card IDs, note IDs, documentation contents, plan IDs, verification IDs, or successful Breadcrumbs updates.

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

1. Resolve the active project by reading `.breadcrumbs/project.json` or following the Project Resolution Flow.
2. Call `get_project_overview` with the resolved `project_id` to learn the project, available columns, and documentation pages.
3. Call `get_kanban_board` with the resolved `project_id` to inspect existing cards and collect card IDs.
4. Match the requested work to an existing card by exact title, clear case-insensitive title match, or obvious description match.
5. If multiple cards reasonably match, ask the user which card to use.
6. If no relevant card exists, call `create_card` with the resolved `project_id`, a concise title, useful description, and the best starting column.
7. Move the target card to `In Progress` or the closest active-work column with `update_card`, unless the user requested a different state.
8. Call `get_card_details` with the resolved `project_id` for the target card.
9. Call `set_card_plan` with the resolved `project_id` and a concrete implementation plan before editing code.
10. Call `set_card_verification` with the resolved `project_id` and the checks you expect to run before completion.
11. Call `log_activity` with the resolved `project_id`, a kickoff entry, and relevant tags.
12. Use `create_note` with the resolved `project_id` for acceptance criteria, notable constraints, or initial technical decisions that should stay attached to the card.

Keep kickoff logs short and concrete:

```text
Started feature: add streamable HTTP MCP support. Plan and verification checklist are attached to the card.
```

## Planning Flow

Use `set_card_plan` whenever you begin substantial implementation work or materially change the approach.

Good plan steps are concrete and verifiable:

```json
{
  "project_id": "project-uuid",
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
  "project_id": "project-uuid",
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
  "project_id": "project-uuid",
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
  "project_id": "project-uuid",
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

## Unified Notes Flow

Use unified notes for durable project or card context that should outlive the current chat thread. This includes acceptance criteria, blockers, review notes, technical decisions, handoff details, manual QA notes, deployment caveats, and project-level reminders.

Create card-attached notes with `create_note` and a `card_id`:

```json
{
  "project_id": "project-uuid",
  "title": "Review focus",
  "content": "Check migration behavior for existing cards and confirm note permissions.",
  "card_id": "card-uuid"
}
```

Create standalone project notes by omitting `card_id`:

```json
{
  "project_id": "project-uuid",
  "title": "Release caveat",
  "content": "Run the latest notes migration before deploying the MCP note tools."
}
```

Use this protocol:

1. Use `list_notes` before creating a durable note if a similar note may already exist.
2. Use `get_note` before materially editing a note.
3. Use `create_note` for new project notes or card-attached notes.
4. Use `update_note` to revise existing note content instead of creating duplicates.
5. Use `delete_note` only when deletion is explicitly requested or the note is clearly obsolete or duplicate.
6. After note changes that affect current work, call `get_card_details` or `list_notes` when confirmation is useful.

Rules:

- Treat `add_note` as a compatibility alias for card notes, not as a separate note system.
- Do not store secrets, API keys, raw tokens, passwords, or private credentials in notes.
- Do not duplicate the same durable context in both a note and documentation unless both audiences need it.
- Prefer notes for card-scoped context and documentation for long-lived procedures or architecture.

## Delete Card Flow

Use `delete_card` only when card deletion is explicitly requested or clearly correct cleanup, such as removing a duplicate card created in error.

Before deleting a card:

1. Call `get_kanban_board` or `get_card_details` to identify the exact card.
2. Confirm the card is unrelated to active work or that the user explicitly asked to delete it.
3. Preserve useful durable context elsewhere when appropriate, such as in documentation or a project note.
4. Call `delete_card` with the exact card ID.
5. Call `get_kanban_board` to confirm the card is gone when confirmation matters.
6. Call `log_activity` only when the deletion is part of meaningful project cleanup.

Never delete a card based only on a vague title match if multiple cards could reasonably match.

## Continue Flow

When continuing existing work:

1. Resolve the active project by reading `.breadcrumbs/project.json` or following the Project Resolution Flow.
2. Call `get_project_overview` and `get_kanban_board` with the resolved `project_id`.
3. Locate the current card. If the user names a card, prefer exact or obvious title matches.
4. Call `get_card_details` with the resolved `project_id` to inspect the existing plan, verification checklist, unified notes, and versions.
5. Move the card to an active column if work is resuming from `Backlog`, `Review`, or a paused state.
6. If no plan exists and implementation work remains, call `set_card_plan` with the resolved `project_id`.
7. If no verification checklist exists and verification will be needed, call `set_card_verification` with the resolved `project_id`.
8. Mark the next active plan step as `doing` with `update_card_plan_steps`.
9. Read relevant documentation pages with `read_documentation` when setup, API behavior, architecture, or prior decisions matter.
10. Review relevant notes with `list_notes` or `get_note` when card context, project reminders, or handoff decisions matter.
11. Log the restart only when the resumed work is substantial or changes the current plan.

## During Work

Sync Breadcrumbs on meaningful state changes, not every file read or edit.

- Use `update_card_plan_steps` when a step starts, completes, or becomes blocked.
- Use `update_card_verification_checks` when checks are run or intentionally skipped.
- Use `log_activity` for milestones, verification summaries, and high-signal progress updates. Always include relevant tags.
- Use `create_note` or `update_note` for durable decisions, blockers, risk, technical debt, handoff notes, or review caveats.
- Use `update_card` if the title, description, scope, or workflow state changes materially.
- Use `delete_card` for explicit or clearly correct card deletion.
- Use `create_card` for newly discovered work that should be tracked separately instead of hiding scope creep inside the current card.
- Use `list_notes`, `get_note`, or `read_documentation` before relying on existing durable context.

Keep `log_activity` focused on the project timeline. Keep notes focused on durable project or card context. Keep plan step notes short and tied to that step.

## Documentation Flow

Use Breadcrumbs documentation for knowledge that should outlive the current thread and is procedural, architectural, or operational: setup steps, environment variables, API contracts, MCP/client configuration, deployment notes, migrations, architecture decisions, and debugging procedures.

Follow this non-destructive edit protocol:

1. Resolve the active project and include `project_id` in every documentation tool call.
2. Call `get_project_overview` to discover existing documentation titles.
3. If the page may already exist, call `read_documentation` first.
4. Merge or append the new information while preserving useful existing content.
5. Call `write_documentation` with the complete updated page content.
6. Use `delete_documentation` only for obsolete or duplicate pages when deletion is intentional.

Never blindly overwrite an existing page with narrower content. Never store secrets, API keys, raw tokens, or private credentials in documentation.

Prefer focused page titles such as:

```text
MCP Server
MCP Client Setup
Feature Lifecycle Workflow
Database & Migrations
Deployment
Notes
```


## User-Scoped Auth And Attribution Rules

Breadcrumbs MCP uses user-scoped API keys.

- A `bcu_...` API key authenticates the user only.
- The active project is never inferred from the API key.
- Old project-scoped MCP keys must not be used for authentication.
- Project access is enforced by Breadcrumbs RBAC on each project-scoped tool call.
- Read tools require project view access.
- Write and delete tools require project edit/admin access.
- MCP-created cards, notes, documentation updates, and activity entries are attributed to the authenticated user API key by Breadcrumbs.

If authentication fails, tell the user to create or check their user-scoped API key in Breadcrumbs Settings or the Welcome setup flow. Do not ask them to create a per-project API key.

## MCP Coverage And Implementation Flow

When the task is to make a project action available to AI agents through MCP, implement the full path rather than only the MCP server wrapper.

For backend work, check and update the relevant layers:

- MCP tool definition, schema, and handler.
- REST route or service function used by the UI.
- Database schema and migrations when the persisted model changes.
- Permission and project membership checks.
- Tests for MCP behavior, REST behavior, and RBAC behavior.

For frontend work, check and update the relevant layers:

- API client types and functions.
- Components or pages that display the project action.
- UI labels that distinguish card description from notes.
- CRUD affordances for unified notes when notes are part of the task.

For unified notes work, treat these as baseline expectations:

- Card details should read card-attached notes from the unified notes table.
- Standalone project notes and card-attached notes should share the same CRUD route family and MCP tool family.
- Legacy card-note creation paths should map into unified notes instead of maintaining a separate note model.
- Migrations should preserve existing notes when moving data into the unified model.

Useful implementation verification includes:

```text
npm run build
python3 -m py_compile backend/mcp_server.py backend/routes/notes.py backend/routes/kanban.py
python3 -m pytest backend/tests/test_mcp.py backend/tests/test_project_rbac.py
make test
```

Run the checks that apply to the repository and environment. If a check cannot run locally, record the limitation in verification evidence.

## Pause And Blocker Flow

When work pauses, blocks, or cannot be completed:

1. Run any checks that are still useful for the partial state.
2. Update the relevant plan step to `blocked` or leave completed steps as `done`.
3. Update verification checks that were run; mark blocked or unrunnable checks as `failed` or `skipped` with evidence, as appropriate.
4. Call `log_activity` with what is complete, what is blocked, and what remains.
5. Call `create_note` or `update_note` with the blocker, reproduction details, or handoff instructions.
6. Move the card to the closest paused, blocked, or active column available on the board. If no such column exists, leave it in `In Progress`.
7. Do not move the card to `Done`.

## Review Flow

When code is ready for human review or PR review:

1. Run the relevant checks first when feasible.
2. Mark all completed plan steps as `done`; leave unresolved work as `todo`, `doing`, or `blocked`.
3. Update verification checks with `passed`, `failed`, or `skipped` and evidence.
4. Call `log_activity` with the review-ready summary, checks run, and known caveats.
5. Add or update a card-attached note for review focus areas, manual QA steps, deployment warnings, or unresolved tradeoffs.
6. Move the card to `Review` or the closest equivalent column.
7. Call `get_kanban_board` to confirm the final card state.

Use `Review` when human QA, deployment, approval, or failed/skipped verification remains.

## Finish Flow

When a feature is complete:

1. Verify with the relevant tests, build, lint, local endpoint probes, or manual checks.
2. Mark every completed plan step as `done` with `update_card_plan_steps`.
3. Mark every verification check as `passed` or `skipped` with evidence. Avoid `skipped` unless there is a clear reason.
4. Update documentation if setup, APIs, architecture, operations, migrations, or MCP/client behavior changed.
5. Create or update a final card-attached note only when there is durable handoff context.
6. Call `log_activity` with the final result, verification performed, and any caveats.
7. Move the card to `Done` only when implementation is complete and verification is acceptable. Move it to `Review` if human QA, deployment, or approval remains.
8. Call `get_kanban_board` to confirm the card landed in the intended final column.

Completion logs should include evidence:

```text
Finished unified notes MCP support. Verified note CRUD through MCP, card details read unified card notes, and frontend build passed.
```

## Status Mapping

Use column names exactly as returned by `get_kanban_board`. Map intent to the closest available column:

- Active implementation: `In Progress`
- Ready for review or QA: `Review`
- Fully implemented and verified: `Done`
- Not started or deferred: `Backlog`

If the board uses different names, choose the closest semantic match and mention the mapping in `log_activity`.

## Safety Rules

- Never move, edit, delete, or annotate an unrelated card.
- Never delete a card or note unless deletion is explicitly requested or clearly correct cleanup.
- Never mark work `Done` before verification unless the user explicitly requests that state.
- Never invent card IDs, note IDs, plan step IDs, or verification check IDs.
- Use project IDs returned by `.breadcrumbs/project.json`, `list_projects`, or `create_project`; use card, note, plan, and verification IDs returned by `create_card`, `get_kanban_board`, `get_card_details`, `create_note`, `list_notes`, `set_card_plan`, `set_card_verification`, or `get_note`.
- Never update plan or verification by list position.
- Never partially retry a failed bulk update without first checking whether anything changed.
- Never store secrets in `.breadcrumbs/project.json`, `log_activity`, notes, plan notes, verification evidence, or documentation.
- Do not repeatedly retry failing MCP calls.
- Do not delete documentation unless deletion is explicitly requested or clearly correct cleanup.
- Keep Breadcrumbs updates useful for reconstructing the work later.

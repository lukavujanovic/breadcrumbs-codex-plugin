# Breadcrumbs Plugin

Breadcrumbs MCP connects coding agents — Codex and Claude Code — to a Breadcrumbs project so they can use the project board, Coding Log, card notes, and documentation while working on features.

## What It Provides

- Plugin manifests for both Codex (`.codex-plugin/`) and Claude Code (`.claude-plugin/`).
- A Streamable HTTP MCP configuration for `https://breadcrumbs.dev/mcp`.
- A `feature-lifecycle` skill that guides agents through starting, updating, and finishing feature work in Breadcrumbs.
- Automatic Coding Log entries (Claude Code only — see below).

## Auto-logging (Claude Code)

When installed in Claude Code, the plugin automatically posts a short summary to your Breadcrumbs project's Coding Log every turn that the working tree of your current git repo changes. The entry contains the touched file paths, a `git diff --stat` summary, and any new commits — but **not** the diff contents (so credentials accidentally edited into a file don't end up in the log).

Detection uses a snapshot of `git rev-parse HEAD` plus a hash of `git diff HEAD` and the untracked-file list, taken at the start of each turn (`UserPromptSubmit` hook) and compared at the end (`Stop` hook). This catches modifications made via the `Edit`/`Write` tools, the `Bash` tool, and even mid-turn `git commit`s.

Requirements: `git`, `jq`, `curl`, and `shasum` on `PATH` (standard on macOS and most Linux distros).

To opt out for a shell session:

```bash
export BREADCRUMBS_AUTOLOG_DISABLED=1
```

To point the auto-logger at a different MCP endpoint (e.g. self-hosted):

```bash
export BREADCRUMBS_MCP_URL=https://your-breadcrumbs.example.com/mcp
```

## Install (Claude Code)

In Claude Code, run:

```
/plugin marketplace add lukavujanovic/breadcrumbs-codex-plugin
/plugin install breadcrumbs-mcp@breadcrumbs-mcp
/reload-plugins
```

Then export your Breadcrumbs MCP token in the shell that launches Claude Code:

```bash
export BREADCRUMBS_MCP_TOKEN=your_token
```

## Update (Claude Code)

For an existing installation, refresh the marketplace first, then update the installed plugin:

```
/plugin marketplace update breadcrumbs-mcp
/plugin update breadcrumbs-mcp@breadcrumbs-mcp
/reload-plugins
```

Terminal equivalent:

```bash
claude plugin marketplace update breadcrumbs-mcp
claude plugin update breadcrumbs-mcp@breadcrumbs-mcp
```

Do not remove and re-add the marketplace just to update. Claude Code removes plugins installed from a marketplace when that marketplace is removed.

This plugin uses the Claude marketplace entry version for update detection. Maintainers must bump `.claude-plugin/marketplace.json` whenever users should receive a new Claude plugin release.

## Repository Layout

```text
.claude-plugin/marketplace.json   # Claude Code marketplace manifest
.claude-plugin/plugin.json        # Claude Code plugin manifest → .mcp.json
.codex-plugin/plugin.json         # Codex plugin manifest → .mcp.codex.json
.mcp.json                         # Claude Code HTTP MCP config (type: http, headers)
.mcp.codex.json                   # Codex HTTP MCP config (bearer_token_env_var)
skills/feature-lifecycle/SKILL.md # Shared agent skill
hooks/hooks.json                  # Claude Code hook config (UserPromptSubmit + Stop)
hooks/snapshot_repo.sh            # Captures repo state at turn start
hooks/log_on_stop.sh              # Diffs at turn end and triggers a log entry
hooks/post_log.sh                 # POSTs log_activity to the MCP server
```

## Security

This repository does not include API keys, bearer tokens, `.env` files, or user project data.

The bundled MCP configs reference the environment variable `BREADCRUMBS_MCP_TOKEN`; the token value is supplied from the user's local environment.

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

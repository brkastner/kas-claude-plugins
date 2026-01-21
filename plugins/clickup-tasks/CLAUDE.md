# clickup-tasks Plugin Instructions

## Core Principle

**NEVER call ClickUp MCP tools directly in main context.**

All ClickUp API operations must be delegated to the `clickup-task-agent` subagent. This keeps the main conversation clean - ClickUp API responses are verbose and would pollute context.

## Commands

| Command | Purpose | Wraps |
|---------|---------|-------|
| `/task:start <id>` | Start work on ClickUp task | kas:start |
| `/task:done` | Complete work, create PR, update ClickUp | kas:verify → kas:done |
| `/task:merge` | Merge PR, close ClickUp task | kas:merge |
| `/task:status [id]` | Check task status | (ClickUp only) |
| `/task:new` | Create new task via interview | (ClickUp only) |

## Subagent Delegation Pattern

When you need ClickUp data, spawn the agent:

```
Task tool with subagent_type="clickup-tasks:clickup-task-agent":
"[Operation]: [specific instructions]
Return ONLY: [concise format]"
```

See `skills/task-workflow/references/subagent-prompts.md` for copy-paste prompts.

## Git Conventions

- **Branches**: `feat/CU-<id>-<slug>` or `fix/CU-<id>-<slug>`
- **Commits**: Include `CU-<task-id>` for ClickUp linking
- **PR titles**: Include `[CU-xxx]` prefix

## Configuration

ClickUp MCP server uses OAuth - authenticate when prompted on first use.

For manual API token setup, see `skills/task-workflow/references/setup.md`.

## Dependencies

This plugin requires:
- `kas` plugin (workflow commands)
- ClickUp MCP server (configured in `.mcp.json`)

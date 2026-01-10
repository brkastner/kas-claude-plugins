# kas Plugin for Claude Code

Workflow automation with beads task tracking, session management, and code review.

## Features

- **Plan Mode**: Structured planning with review agents before implementation
- **Beads Integration**: Automatic daemon startup, issue tracking, dependency management
- **Session Management**: Multi-session workflows with context preservation
- **Code Review**: Parallel code quality + reality assessment
- **Browser Automation**: Subagent-based web testing and scraping

## Prerequisites

Install these plugins first:
- `commit-commands` - Git commit automation
- `pr-review-toolkit` - Code review agents
- `context7` - Library documentation lookups

## Installation

### Option 1: Add Marketplace

```bash
# Add the marketplace
/plugin marketplace add brkastner/kas-plugins

# Install the plugin
/plugin install kas@kas-plugins
```

### Option 2: Local Development

```bash
# Clone the repo
git clone https://github.com/brkastner/kas-plugins.git ~/dev/kas-plugins

# Use with Claude Code
claude --plugin-dir ~/dev/kas-plugins
```

## Complete Workflow

```
PLAN MODE
├─ Write implementation plan
├─ plan-reviewer (auto) → summarizes findings
├─ task-splitter (auto) → prepares bd create commands
└─ ExitPlanMode → user reviews plan + findings + commands
       ↓
USER APPROVAL (approves everything at once)
├─ Claude executes bd create commands
├─ Claude stops (provides next session prompt)
└─ User: /clear (free context)
       ↓
IMPLEMENTATION (one or more sessions)
├─ [Paste continuation prompt]
├─ bd ready → pick issue → implement
├─ /kas:verify (code + reality review)
├─ Quality gates (tests, linting)
├─ /kas:save (if continuing) OR /kas:done (if complete)
└─ [If /kas:save: /clear → next session]
       ↓
FINALIZATION
├─ /kas:done → commit, push, close issues
├─ Create PR (gh pr create)
└─ /kas:merge → merge to main, delete branch
```

### Multi-Session Pattern

```
Session 1: Plan → Review → Create beads → /clear
Session 2: [Paste prompt] → Implement → /kas:save → /clear
Session 3: [Paste prompt] → Complete → /kas:done → /kas:merge
```

## Commands

| Command | Description |
|---------|-------------|
| `/kas:done` | Complete session: commit, push, close issues, verify daemon |
| `/kas:save` | Snapshot session: push work, generate continuation prompt |
| `/kas:next` | Find next available beads issue to work on |
| `/kas:merge` | Merge PR to main, delete branch |
| `/kas:verify` | Tiered verification: static → reality → simplifier with early-exit |
| `/kas:review-code` | Standalone code quality review (Linus Torvalds style) |
| `/kas:review-reality` | Standalone reality assessment (skeptical validation) |
| `/kas:review-plan` | Review plan for security gaps and design issues |

### Session Commands

**`/kas:done`** - Complete and finalize
- Closes beads issues
- Commits and pushes (MANDATORY - work incomplete until push succeeds)
- Adds PR comment if PR exists
- Verifies daemon running
- Suggests next task

*Note: Quality gates should be run before /kas:done*

**`/kas:save`** - Pause for later
- Commits and pushes current work
- Adds PR comment with session snapshot (if PR exists)
- Generates continuation prompt for next session
- Use `/clear` afterward to free context

**`/kas:next`** - Find work
- Shows unassigned beads issues ready to work
- Recommends which to claim

### Review Commands

**`/kas:verify`** - Tiered verification with early-exit
- **Tier 1** (parallel): 5 static analysis agents
  - kas: code-reviewer
  - pr-review-toolkit: silent-failure-hunter, comment-analyzer, type-design-analyzer, pr-test-analyzer
  - Exit: critical/high → BLOCKED, medium → NEEDS CHANGES
- **Tier 2** (if Tier 1 clean): project-reality-manager
  - Exit: issues → NEEDS CHANGES/BLOCKED
- **Tier 3** (if VERIFIED): code-simplifier for optional improvements

**`/kas:review-code`** - Code quality only
- Ruthless Linus Torvalds style review
- Severity levels: Critical (91-100), High (71-90), Medium (41-70), Low (1-40)

**`/kas:review-reality`** - Reality check only
- Validates claimed completions with extreme skepticism
- Gap analysis between claimed and actual functionality

## Agents

| Agent | Purpose | Trigger |
|-------|---------|---------|
| `plan-reviewer` | Review plans for gaps/security | Auto after plan written |
| `task-splitter` | Decompose plans into beads issues | Auto after plan-reviewer |
| `code-reviewer` | Ruthless code quality review | Via /kas:review-code or /kas:verify |
| `project-reality-manager` | Validate claimed completions | Via /kas:review-reality or /kas:verify |
| `browser-automation` | Web testing and automation | Detected via skill pattern |

### Agent Workflow

1. **plan-reviewer** runs automatically after you write a plan
2. **task-splitter** runs automatically after plan-reviewer
3. ExitPlanMode → you review plan + findings + commands together
4. You approve → Claude executes `bd create` commands
5. Claude stops with continuation prompt
6. You `/clear` → implementation happens in fresh session

## Critical Rules

These rules are non-negotiable:

1. **Work is NOT complete until `git push` succeeds**
   - Never stop before pushing
   - Never say "ready to push when you are" - Claude must push

2. **Summarize findings before proceeding**
   - After plan-reviewer: summarize → get approval
   - After code review: summarize → get approval
   - Never auto-apply fixes

3. **Quality gates must pass**
   - Run tests before committing
   - Fix failures before marking complete

4. **Plan mode order matters**
   - plan-reviewer → task-splitter → ExitPlanMode → user approval
   - User approves plan + findings + commands together before execution

## Beads Integration

### Automatic Setup

The plugin starts the beads daemon automatically on session start:
```bash
bd daemon --start --auto-commit --auto-push
```

This syncs beads data to the `util/beads-sync` branch automatically.

### Key Commands

```bash
bd ready --unassigned  # Find unclaimed work
bd show <id>           # View issue details
bd update <id> --claim # Claim issue (sets assignee + in_progress)
bd close <id>          # Complete work
bd daemon --status     # Verify daemon running
```

### Starting Work

```bash
bd show <id>                      # Review issue
bd update <id> --claim            # Claim it
git checkout -b feat/<id>-slug    # Create branch
git push -u origin feat/<id>-slug # Push branch
```

### Issue Categories

- **Explore**: Research, codebase analysis
- **ADR**: Architecture decisions, design spikes
- **Implement**: Code changes, features
- **Document**: Patterns, guides, API docs
- **Fix**: Bug fixes, tech debt

### Sibling Pattern Corrections

Before implementing, check closed sibling issues (same plan/epic) for pattern corrections discovered during implementation.

## Browser Automation

The browser skill delegates web tasks to a subagent, keeping your main context clean.

**Triggers**: Any request involving web interaction, testing, scraping

**How it works**:
1. Main context detects browser task
2. Delegates to `browser-automation` agent via Task tool
3. Subagent uses claude-in-chrome MCP tools
4. Returns concise summary (no raw HTML/verbose logs)

## Configuration

### Project CLAUDE.md

When a project has its own CLAUDE.md:
- Project instructions take precedence
- Plugin provides base workflow
- Project adds specifics (quality gates, conventions)

### Beads Setup

Each project needs beads initialized:
```bash
bd init
bd daemon --start --auto-commit --auto-push
```

### Branch Naming

- Features: `feat/<id>-<description>`
- Bug fixes: `fix/<id>-<description>`
- Refactors: `refactor/<id>-<description>`

### Quality Gates

Customize per project:
```bash
# JavaScript/TypeScript
npm test && npm run lint

# Python
pytest && ruff check .

# Rust
cargo test && cargo clippy

# Go
go test ./... && golangci-lint run
```

## Hooks

### SessionStart

Ensures beads daemon is running with auto-sync enabled:
- Only runs in directories with `.beads/`
- Silent operation (no warnings)
- Never fails (always exits 0)

## Troubleshooting

### Git push fails
```bash
git pull --rebase
# Resolve conflicts if any
git push
```

### Daemon not running
```bash
bd daemon --status
bd daemon --start --auto-commit --auto-push
```

### Worktree cleanup
```bash
git worktree list
git worktree remove <path>
```

## License

MIT

# kas Plugin

Workflow automation with beads task tracking, session management, and code review.

## Features

- **Plan Mode**: Structured planning with review agents before implementation
- **Beads Integration**: Automatic daemon startup, issue tracking, dependency management
- **Session Management**: Multi-session workflows with context preservation
- **Code Review**: Parallel code quality + reality assessment
- **Browser Automation**: Subagent-based web testing and scraping

## Prerequisites

- **Beads CLI** (`bd`) - Local-first issue tracking: `cargo install beads`
- **GitHub CLI** (`gh`) - For PR workflows
- **pr-review-toolkit plugin** - Code review agents

## Commands

| Command | Description |
|---------|-------------|
| `/kas:setup` | Prepare project: validate prerequisites, init beads, configure daemon |
| `/kas:done` | Complete session: commit, push, close issues |
| `/kas:save` | Snapshot session: push work, generate continuation prompt |
| `/kas:next` | Find next available beads issue |
| `/kas:merge` | Merge PR to main, cleanup worktree |
| `/kas:verify` | Tiered verification: static -> reality -> simplifier |
| `/kas:review-code` | Standalone code review (Linus Torvalds style) |
| `/kas:review-reality` | Standalone reality assessment |
| `/kas:review-plan` | Review plan for security/design issues |

## Agents

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `plan-reviewer` | Review plans for gaps/security | Auto after plan written |
| `task-splitter` | Decompose plans into beads issues | Auto after plan-reviewer |
| `code-reviewer` | Code quality review | Via /kas:review-code or /kas:verify |
| `project-reality-manager` | Validate claimed completions | Via /kas:review-reality or /kas:verify |
| `browser-automation` | Web testing and automation | Via browser skill |

## Workflow

```
Plan Mode -> plan-reviewer -> task-splitter -> ExitPlanMode -> User Approval
                                                                    |
                                                                    v
Implementation -> bd ready -> Implement -> /kas:verify -> Quality Gates
                                                                    |
                                                                    v
Completion -> /kas:done (commit, push, close) -> /kas:merge (PR, cleanup)
```

### Multi-Session Pattern

```
Session 1: Plan -> Review -> Create beads -> /clear
Session 2: [Paste prompt] -> Implement -> /kas:save -> /clear
Session 3: [Paste prompt] -> Complete -> /kas:done -> /kas:merge
```

## Beads Integration

### Automatic Daemon

Plugin starts beads daemon on session start:
```bash
bd daemon --start --auto-commit --auto-push
```

### Key Commands

```bash
bd ready --unassigned  # Find unclaimed work
bd show <id>           # View issue details
bd update <id> --claim # Claim issue
bd close <id>          # Complete work
```

### Issue Categories

- **Explore**: Research, codebase analysis
- **ADR**: Architecture decisions
- **Implement**: Code changes, features
- **Document**: Patterns, guides
- **Fix**: Bug fixes, tech debt

## Critical Rules

1. **Work is NOT complete until `git push` succeeds**
2. **Summarize findings before proceeding** (after reviews)
3. **Quality gates must pass** before committing
4. **Plan mode order matters**: plan-reviewer -> task-splitter -> ExitPlanMode

## Configuration

### Quality Gates

Customize per project:
```bash
npm test && npm run lint     # JavaScript
pytest && ruff check .       # Python
cargo test && cargo clippy   # Rust
go test ./... && golangci-lint run  # Go
```

### Branch Naming

- Features: `feat/<id>-<description>`
- Bug fixes: `fix/<id>-<description>`
- Refactors: `refactor/<id>-<description>`

## Hooks

### SessionStart

Ensures beads daemon runs with auto-sync:
- Only activates in directories with `.beads/`
- Silent operation (no warnings)

## Troubleshooting

```bash
# Git push fails
git pull --rebase && git push

# Daemon not running
bd daemon --status
bd daemon --start --auto-commit --auto-push

# Worktree cleanup
git worktree list
git worktree remove <path>
```

## License

MIT

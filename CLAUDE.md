# kas Plugin - Claude Code Workflow Instructions

## Context7 Documentation Lookups

**Always use Context7** when looking up library/framework documentation:
- Ensures latest version is referenced (not stale training data)
- Workflow: `resolve-library-id` → `query-docs` → implement
- Use for: code generation, setup steps, API documentation

## How to Use Context

- Your context window will be automatically compacted as it approaches its limit
- Never stop tasks early due to token budget concerns - complete tasks fully
- When writing code, write code as Linus Torvalds would: simple, correct, readable
- When running a sub-agent that does a review, **summarize the findings to me before acting on the results**

## Complete Workflow

```
Plan Mode (for new features)
    ↓
Plan Reviewer → Task Splitter → Land the plane (branch + beads on GitHub)
    ↓
Session Start: "start on beads-xxx" → Create branch
    ↓
bd ready → Pick subtask → Implement
    ↓
Review (pr-review-toolkit) → Quality Gates
    ↓
Claude: Summarizes → "Approve?"
User: Responds with shortcut or explicit approval
    ↓
Session boundary:
├─ Work complete: User: /kas:done → Claude creates PR → User: /kas:merge
└─ Work continues: User: /kas:save → User: /clear → Resume next session
```

**Key:** `/kas:done`, `/kas:save`, `/kas:merge`, `/clear` are USER shortcuts, not Claude automation

**User Checkpoints (mandatory):**
1. After plan-reviewer + task-splitter: user approves plan, findings, and bd commands together
2. After code review agents: summarize findings, get approval before fixes
3. After code-simplifier: summarize suggestions, get approval before applying

## Plan Mode

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.
- Every plan should include high level requirements, architecture decisions, data models, and a robust testing strategy
- Do not save tests for the end - testing should be alongside the relevant requirements
- The first thing you should do after I accept a plan is run the **Task Splitter** sub-agent to create beads issues

### Plan Reviewer Agent

After creating a plan, run the plan-reviewer agent automatically:
```
"Review this plan for security gaps and design issues"
```

The agent returns structured feedback. Then immediately run task-splitter.

### Task Splitter Agent

After plan-reviewer completes, run task-splitter automatically:
```
"Split this plan into beads issues"
```

The agent outputs `bd create` commands. Then call ExitPlanMode so user can review everything together (plan + findings + commands).

### After Plan Approval

When user approves (plan + findings + commands shown via ExitPlanMode):

1. **Create worktree for plan:**
   ```bash
   REPO_ROOT=$(git rev-parse --path-format=absolute --git-common-dir | sed 's/\.git$//')
   # Derive prefix from plan title: Fix:/Bug: → fix/, Refactor: → refactor/, default → feat/
   PREFIX="feat"  # or fix/refactor based on title
   SLUG=$(echo "$PLAN_TITLE" | sed 's/^[^:]*: //' | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | tr -cd 'a-z0-9-' | cut -c1-30 | sed 's/-$//')
   BRANCH="$PREFIX/$SLUG"
   WORKTREE_PATH="$REPO_ROOT/.worktrees/$PREFIX-$SLUG"

   mkdir -p "$REPO_ROOT/.worktrees"
   git worktree add -b "$BRANCH" "$WORKTREE_PATH" main
   git -C "$WORKTREE_PATH" push -u origin "$BRANCH"
   ```

2. **Execute bd create commands** → create beads issues

3. **Output:**
   ```
   Worktree ready: .worktrees/$PREFIX-$SLUG/
   Branch: $BRANCH
   Issues created: <count>

   Switch to it:
   cd $WORKTREE_PATH
   ```

4. **Stop** - user runs `cd` and `/clear` for fresh session

This enables the next session to immediately start implementing in an isolated worktree.

## Working with Beads

Beads is used for **all granular work tracking**:
- **Exploratory work**: Research, codebase analysis, architecture decisions (`Explore: ...`)
- **Planning**: Design decisions, spike investigations (`ADR: ...`)
- **Implementation**: Code changes, tests, refactoring subtasks (`Implement: ...`)
- **Tech debt**: Internal improvements, cleanup, optimizations (`Fix: ...`)
- **Documentation**: Patterns, setup guides, API docs (`Document: ...`)

### Key Commands

```bash
bd ready --unassigned # Find unclaimed work (unblocked, not claimed)
bd show <id>          # View issue details
bd update <id> --claim  # Atomically claim (sets assignee + in_progress)
bd close <id>         # Complete work
bd daemon --status    # Check daemon is running (auto-syncs to util/beads-sync)
```

### Starting Work on an Issue

Before implementing, check for pattern corrections:
1. **Identify sibling issues** - Issues from the same plan/epic (check description for shared reference)
2. **Check closed siblings** - Run `bd list --status=closed` and look for related issues
3. **Read close reasons** - Close reasons often contain pattern corrections discovered during implementation
4. **Apply learnings** - If a sibling was corrected, apply that to your issue

This prevents repeating mistakes that were already caught and corrected.

### Issue Descriptions

Treat beads issue descriptions like GitHub issues. Include:
- Context needed for another developer to pick up this task
- Code references with file and line numbers
- Reasoning and architectural decisions
- Links to related plan files or issues

### Finding Work During Implementation

1. Use `bd ready --unassigned` to find next subtask
2. `bd update <id> --claim` to claim it
3. Close subtasks as you complete them
4. When all beads issues are closed, automatically start the code review workflow

**Rules:**
- Never ask about already-claimed issues. Only show unassigned work when finding next tasks.

### Direct Beads Workflow

**Start work:**
```bash
bd show <id>                           # View issue details
bd update <id> --claim                 # Atomically claim it
git checkout -b feat/<id>-slug         # Create branch
git push -u origin feat/<id>-slug
```

**Complete work:**
1. Run quality gates
2. `bd close <id>`
3. Commit + push
4. Create PR: `gh pr create`
5. Use `/kas:merge` to finalize

## Git Worktree Workflow

One worktree is created per plan after approval. All issues from that plan are worked in the same worktree.

### Automatic Creation

After plan approval, Claude:
1. Creates branch + worktree from plan title
2. Executes `bd create` commands for all issues
3. Outputs `cd` command for user to switch

### Conventions

| Element | Format | Example |
|---------|--------|---------|
| Path | `.worktrees/<prefix>-<slug>/` | `.worktrees/feat-user-auth/` |
| Branch | `<prefix>/<slug>` | `feat/user-auth` |

**Prefix derivation:**
- Plan title starts with "Fix:" or "Bug:" → `fix/`
- Plan title starts with "Refactor:" → `refactor/`
- Default → `feat/`

### Working in Worktree

```bash
cd <worktree-path>          # Switch to worktree
/kas:next                   # Claim next issue (no new worktree created)
# ... work ...
/kas:done                   # Commit + push
/kas:merge                  # Merge PR + auto-cleanup worktree
```

- Use absolute paths for all file operations
- Main repo stays on `main` branch
- `/kas:next` in worktree skips worktree creation (already in one)

### Commit Messages

Include issue reference:
```
feat: implement user authentication

Refs: beads-abc123
```

### PR Workflow

- PR created after first commit (via `/kas:done` then `gh pr create`)
- Always work on feat/ or fix/ branches
- Never commit directly to main unless explicitly requested
- `/kas:merge` cleans up worktree after merging

## Code Review (pr-review-toolkit)

Run relevant agents **before commits**. Agent selection based on what changed:
- Any code changes → `code-reviewer`
- Error handling (try/catch, catch blocks) → + `silent-failure-hunter`
- Comments, docstrings, JSDoc → + `comment-analyzer`
- Type definitions, interfaces, schemas → + `type-design-analyzer`
- Before PR creation → + `pr-test-analyzer`
- After review passes → `code-simplifier` (optional)

### Running Reviews

```bash
# General code review
"Review my recent changes"

# Specific focus
"Check for silent failures in error handling"
"Analyze the comments I added"
"Review the type design for the new models"
```

### Running Multiple Agents

**Parallel** (faster):
```
"Run pr-test-analyzer and comment-analyzer in parallel"
```

**Sequential** (when one informs the other):
```
"First review test coverage, then check code quality"
```

### Review Workflow

1. Run relevant agents
2. **Summarize findings to user**
3. User approves fixes or provides direction
4. Implement fixes
5. Re-run if needed
6. Proceed to quality gates

## Quality Gates

Run before committing. Customize based on your project:

```bash
# Example patterns
npm test              # JavaScript/TypeScript
pytest                # Python
cargo test            # Rust
go test ./...         # Go

# Linting
npm run lint
ruff check .
cargo clippy
```

## Testing Requirements

- Write tests for all new functionality
- Check for proper test coverage using `pr-review-toolkit:pr-test-analyzer`
- Run tests until all pass before marking task complete
- Commit only when tests are green

## Landing the Plane

*Note: same as calling /kas:done*

**When I say "let's land the plane"**, you MUST complete ALL steps below. The plane is NOT landed until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File beads issues for any remaining work** that needs follow-up
2. **Run quality gates** (only if code changes were made)
3. **Ensure all quality gates pass**
4. **Update beads issues** - close finished work, update status
5. **PUSH TO REMOTE - NON-NEGOTIABLE**:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin/*"
   ```
6. **Add PR comment** (if PR exists):
   - Run: `gh pr view` to check for PR
   - If found: add completion comment with summary
   - If not found: skip gracefully
7. **Clean up git state**:
   ```bash
   git stash clear
   git remote prune origin
   ```
8. **Verify clean state** - All changes committed AND pushed
9. **Verify daemon running**:
   ```bash
   bd daemon --status || echo "Warning: daemon not running"
   ```
10. **Choose follow-up issue** - Provide prompt for next session

**Note**: Beads data syncs automatically via daemon to `util/beads-sync` branch. No manual `bd sync` needed.

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are!" - YOU must push
- If push fails, resolve and retry until it succeeds

**Then provide:**
- Summary of what was completed
- What issues were filed for follow-up
- Status of quality gates
- Confirmation that ALL changes have been pushed
- Recommended prompt for next session

## Session Management

**These are user shortcuts that preserve the approval flow:** Claude still summarizes and asks for approval before taking action. The user responds with shortcuts instead of verbose approval.

### Approval Shortcuts

**Traditional flow:**
```
Claude: "I've completed the implementation. Quality gates pass. Approve?"
User: "Yes, looks good, please proceed"
Claude: [Executes landing the plane]
```

**With shortcuts:**
```
Claude: "I've completed the implementation. Quality gates pass. Approve?"
User: "/kas:done"
Claude: [Executes landing the plane]
```

### /kas:save - Session Snapshot

**When to use:** Multi-session work. Need to pause and free context.

**User types:** `/kas:save`

**Claude responds by:**
1. Taking session snapshot
2. Adding PR comment with status + next prompt
3. Landing the plane (push to remote)
4. Outputting next session prompt to copy

**Scenario:**
- Beads issues remain open
- Feature partially complete
- Need to free context and continue later

### /clear - Context Reset

**When to use:** After `/kas:save` to free context window

**User types:** `/clear`

**Effect:** Compacts conversation history, maintains critical context, enables fresh start

### /kas:next - Find Next Work

**When to use:** Find available beads issues to work on

**User types:** `/kas:next`

**Claude responds by:**
1. Running `bd ready --unassigned`
2. Showing issues in priority order
3. If single issue: asking "Claim it?"
4. If multiple: letting user pick

### Multi-Session Workflow

```
Session 1: Work → Claude asks approval → User: "/kas:save" → User: "/clear"
Session 2: User: [Paste prompt] → Continue → User: "/kas:save" → User: "/clear"
Session 3: User: [Paste prompt] → Complete → User: "/kas:done" → User: "/kas:merge"
```

## PR Merging & Finalization

### /kas:merge - Finalize and Merge PR

**User shortcut** to finalize a feature and merge to main. User types this when ready to merge (typically after PR review passes).

**Usage:**
```bash
/kas:merge              # Infer PR from current branch
/kas:merge 123          # Specific PR number
/kas:merge <PR-URL>     # Direct PR URL
```

**When user types `/kas:merge`, Claude will:**
1. Validate CI passes (waits if pending, asks user if failed)
2. Merge to main with merge commit (preserves code history)
3. Clean up worktree (if applicable)
4. Report completion

**Requirements:**
- CI must pass (green checks)
- No merge conflicts
- Branch must not be main

**User typing `/kas:merge` = user approval to merge** - Claude proceeds without additional confirmation.

## Prerequisites

This plugin works best with these other plugins installed:
- `commit-commands` - Git commit automation
- `pr-review-toolkit` - Code review agents
- `context7` - Library documentation lookups

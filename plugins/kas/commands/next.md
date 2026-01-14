# /kas:next - Find Next Work

Show available beads issues and suggest one to work on.

## Workflow

### 1. Show Unclaimed Issues
```bash
bd ready --unassigned
```

### 2. Analyze and Recommend

Review the ready issues and suggest ONE to work on based on:
- **Priority**: Lower number = higher priority (P0 > P1 > P2)
- **Dependencies**: Issues that unblock others are more valuable
- **Type**: Bugs before features, unless priority says otherwise
- **Context**: If there's a current task in progress, prefer related work

### 3. Output Format

**Single issue available:**
```
| ID | Priority | Title |
|----|----------|-------|
| <id> | P# | <title> |

Claim it?
```

Wait for user confirmation, then run `bd update <id> --claim`.

**Multiple issues available:**
```
| ID | Priority | Title |
|----|----------|-------|
| <id1> | P# | <title1> |
| <id2> | P# | <title2> |
...
```

Let user pick which one to work on.

## Worktree Handling

Detect worktree via `git rev-parse --git-common-dir` vs `--show-toplevel`.

- **In worktree**: Claim only, no new worktree. Output: "Claimed `<id>`. Ready to work."
- **In main repo**: Normal behavior (worktrees created at plan approval).

## Rules

- Always run `bd ready --unassigned` fresh - don't rely on cached info
- If no issues are ready, suggest running `bd blocked` to see what's stuck
- If user is in a worktree, prioritize issues related to that feature
- Keep recommendation reasoning brief (1-2 sentences max)

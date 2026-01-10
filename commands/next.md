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

Detect worktree context before claiming:

```bash
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null)

# If COMMON_DIR != TOPLEVEL/.git, we're in a worktree
if [[ "$COMMON_DIR" != "$TOPLEVEL/.git" ]]; then
  IN_WORKTREE=true
fi
```

**If in worktree:**
- Skip worktree creation (already in one)
- Claim issue only: `bd update <id> --claim`
- Output: "Claimed `<id>`. Already in worktree, ready to work."

**If in main repo:**
- Normal behavior (worktrees created at plan approval, not here)

## Rules

- Always run `bd ready --unassigned` fresh - don't rely on cached info
- If no issues are ready, suggest running `bd blocked` to see what's stuck
- If user is in a worktree, prioritize issues related to that feature
- Keep recommendation reasoning brief (1-2 sentences max)

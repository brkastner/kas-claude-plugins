# /kas:save - Session Snapshot

Save session progress for continuation across multiple sessions. Unlike `/kas:done`, this doesn't close all work - it creates a snapshot and generates a continuation prompt.

## Arguments
- `$ARGUMENTS` - Optional context or notes to include in the snapshot

## When to Use

- Pausing work that will continue in another session
- Freeing context without losing progress
- Creating a checkpoint before switching tasks

## Instructions

### 1. Collect Session State

```bash
git status --short
bd list --status=open
git log --oneline -5
```

### 2. Generate Session Summary

Review and summarize:
- **Completed work**: Closed beads issues or recent commits
- **In-progress work**: Open beads issues with `in_progress` status
- **Quality gate status**: Results if run this session
- **Blockers**: Any issues preventing progress

### 3. Stage and Commit Changes (if any)

If there are unstaged changes:
```bash
git add <relevant-files>
git commit -m "<appropriate message>"
```

### 4. Push to Remote

```bash
git pull --rebase
git push
```

Beads data syncs automatically via daemon to `util/beads-sync` branch.

### 5. Add PR Comment (if PR exists)

Check for existing PR:
```bash
gh pr view --json url -q .url 2>/dev/null
```

If PR exists, add session snapshot comment:

```bash
gh pr comment --body "$(cat <<'EOF'
## Session Snapshot - {date}

**Completed:**
- {completed_items}

**Quality Gates:** {status}

**Beads Status:**
- Closed: {closed_list}
- In Progress: {in_progress_list}

**Next Session Prompt:**
```
{next_prompt}
```
EOF
)"
```

### 6. Clean Up Git State

```bash
git stash clear
git remote prune origin
```

### 7. Verify Clean State

```bash
git status
```

Must show branch is up to date with origin.

### 8. Verify Daemon Running
```bash
bd daemon --status || echo "Warning: daemon not running, beads may not have synced"
```

### 9. Output Next Session Prompt

Generate and display prominently for user to copy:

```
Continue work on {feature-name}:
- Resume: {current in-progress beads issue}
- Next: {next ready task from bd ready}
- Context: {brief context about blockers or pending work}
```

Display this in a code block for easy copying.

## Key Differences from /kas:done

| Aspect | /kas:save | /kas:done |
|--------|-----------|-----------|
| Work status | Keeps work open | Closes completed work |
| Focus | Session boundary | Task completion |
| Prompt | Continuation-focused | Next task suggestion |
| PR comment | Session snapshot | Optional |

## Rules

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- If push fails, resolve and retry until it succeeds
- Do NOT close beads issues unless they are truly complete
- Always generate the next session prompt for easy continuation

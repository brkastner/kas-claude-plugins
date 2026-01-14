# /kas:done - Land the Plane

Complete the current session by ensuring all work is committed and pushed.

## Workflow

Execute these steps in order:

### 1. Check Git Status
```bash
git status
```

### 2. Stage and Commit Code Changes (if any)
If there are unstaged changes:
```bash
git add <relevant-files>
git commit -m "<appropriate message>"
```

### 3. Push to Remote
```bash
git pull --rebase
git push
git status  # MUST show "up to date with origin/*"
```

### 4. Add PR Comment (if PR exists)

If on feature branch with open PR, add completion comment:

```bash
# Check for PR
PR_URL=$(gh pr view --json url -q .url 2>/dev/null)

if [[ -n "$PR_URL" ]]; then
  gh pr comment --body "$(cat <<'EOF'
## Session Complete

**Completed:**
{completed_items}

**Quality Gates:** {status}

**All changes pushed to remote.**
EOF
)"
fi
```

Skip gracefully if no PR exists.

### 5. Clean Up Git State
```bash
git stash clear
git remote prune origin
```

### 6. Verify Clean State
```bash
git status
```
Must show branch is up to date with origin.

### 7. Verify Daemon Running
```bash
bd daemon --status || echo "Warning: daemon not running, beads may not have synced"
```

### 8. Show Summary

Provide:
- **Completed**: What was done this session
- **Quality gates**: Status (passed/skipped/N/A)
- **Git state**: Confirmation all changes pushed
- **Remaining work**: Output of `bd ready`
- **Next session prompt**: Recommended command to continue work

## Rules

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- If push fails, resolve and retry until it succeeds
- Only run quality gates if code changes were made
- Close any beads issues that were completed (daemon auto-syncs to `util/beads-sync`)

## Beads Sync

Beads data syncs automatically via daemon to `util/beads-sync` branch. No manual `bd sync` needed unless you need immediate sync before a merge operation.

# /kas:merge - Merge PR

Finalize and merge a pull request after work is complete and approved.

## Arguments
- `$ARGUMENTS` - Optional: PR number or PR URL

## Instructions

### 1. Resolve Target PR

```bash
# If argument provided, resolve it
# Otherwise check current branch for open PR
gh pr view $ARGUMENTS --json number,headRefName,title,state,mergeable,url
```

If no PR found or ambiguous, ask user which PR to merge.

### 2. Validate Merge Eligibility

Check the PR JSON response:
- `state` must be `OPEN`
- `headRefName` must not be `main`
- `mergeable` must be `MERGEABLE`

If conflicts exist (`mergeable` = `CONFLICTING`), abort:
> Cannot merge: PR has conflicts. Please resolve conflicts first.

### 3. Check CI Status

```bash
gh pr checks <PR#> --json name,status,conclusion
```

| Status | Action |
|--------|--------|
| All COMPLETED + SUCCESS | Proceed to step 4 |
| Any COMPLETED + FAILURE | Attempt auto-fix (check logs, re-run). If can't fix, ask user. |
| Any IN_PROGRESS | Wait with progress indication (max 5 min, check every 30s) |

If CI doesn't pass after waiting/fixing, ask user for guidance.

### 4. Merge PR

```bash
gh pr merge <PR#> --merge --delete-branch
```

### 5. Cleanup Worktree (if applicable)

```bash
# Check if in worktree
WORKTREE_PATH=$(pwd)
if [[ "$WORKTREE_PATH" == *"/.worktrees/"* ]]; then
  MAIN_REPO=$(git rev-parse --path-format=absolute --git-common-dir | sed 's/\.git$//')
  cd "$MAIN_REPO"
  git worktree remove "$WORKTREE_PATH" --force
fi
```

### 6. Verify and Report

```bash
gh pr view <PR#> --json state,mergedAt
```

Provide summary:
- **PR merged**: #{number} - {title}
- **Worktree cleaned**: Yes/No/N/A
- **Branch deleted**: Yes

## Rules

- NEVER merge to main directly - always use PR workflow
- NEVER skip CI checks - wait or ask user
- ALWAYS use `--merge` flag (preserve branch history)
- ALWAYS delete remote branch after merge (`--delete-branch`)
- If in worktree, MUST clean it up after merge
- Beads commits go to `util/beads-sync` branch (not feature branches), so no squashing needed

## Error Handling

| Error | Action |
|-------|--------|
| No PR found | Ask user to specify PR |
| Merge conflicts | Abort, tell user to resolve conflicts first |
| CI failing | Attempt auto-fix, then ask user |
| CI timeout (>5 min) | Ask user whether to wait more or proceed |
| Worktree removal fails | Log warning, continue |

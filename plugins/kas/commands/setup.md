# /kas:setup - Prepare Project for KAS Workflow

Validate prerequisites, initialize beads, configure daemon, and verify the environment is ready.

## Workflow

Execute these steps in order. Track results as PASS, FAIL (blocker), or WARN (non-blocking).

### 1. Check Prerequisites

Prerequisites are **BLOCKERS** - setup cannot continue if any fail.

#### 1.1 Check beads CLI (bd)

```bash
# Check installed
if ! command -v bd &>/dev/null; then
  echo "[FAIL] bd not found"
  echo "  Install: cargo install beads"
  echo "  Or: https://github.com/brkastner/beads"
  # BLOCKER - stop here
fi

# Check version >= 0.5.0
BD_VERSION=$(bd --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [[ -z "$BD_VERSION" ]]; then
  echo "[FAIL] Could not determine bd version"
  # BLOCKER
fi

# Compare versions (0.5.0 minimum)
BD_MAJOR=$(echo "$BD_VERSION" | cut -d. -f1)
BD_MINOR=$(echo "$BD_VERSION" | cut -d. -f2)
BD_MAJOR=${BD_MAJOR:-0}
BD_MINOR=${BD_MINOR:-0}
if [[ "$BD_MAJOR" -eq 0 && "$BD_MINOR" -lt 5 ]]; then
  echo "[FAIL] bd version $BD_VERSION < 0.5.0"
  echo "  Upgrade: cargo install beads --force"
  # BLOCKER
else
  echo "[PASS] bd $BD_VERSION"
fi
```

#### 1.2 Check GitHub CLI (gh)

```bash
# Check installed
if ! command -v gh &>/dev/null; then
  echo "[FAIL] gh not found"
  echo "  Install: https://cli.github.com/"
  # BLOCKER
fi

# Check version >= 2.0.0
GH_VERSION=$(gh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
GH_MAJOR=$(echo "$GH_VERSION" | cut -d. -f1)
GH_MAJOR=${GH_MAJOR:-0}
if [[ "$GH_MAJOR" -lt 2 ]]; then
  echo "[FAIL] gh version $GH_VERSION < 2.0.0"
  echo "  Upgrade: https://cli.github.com/"
  # BLOCKER
fi

# Check authenticated
if ! gh auth status &>/dev/null; then
  echo "[FAIL] gh not authenticated"
  echo "  Run: gh auth login"
  # BLOCKER
fi

# Check repo scope
GH_SCOPES=$(gh auth status 2>&1 | grep -i "token scopes" || true)
if [[ -z "$GH_SCOPES" ]] || ! echo "$GH_SCOPES" | grep -qi "repo"; then
  echo "[FAIL] gh missing 'repo' scope"
  echo "  Run: gh auth refresh -s repo"
  # BLOCKER
else
  echo "[PASS] gh $GH_VERSION (authenticated, repo scope)"
fi
```

#### 1.3 Check Git Configuration

```bash
# Check version >= 2.20.0
GIT_VERSION=$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)
GIT_MAJOR=${GIT_MAJOR:-0}
GIT_MINOR=${GIT_MINOR:-0}
if [[ "$GIT_MAJOR" -lt 2 ]] || [[ "$GIT_MAJOR" -eq 2 && "$GIT_MINOR" -lt 20 ]]; then
  echo "[FAIL] git version $GIT_VERSION < 2.20.0"
  # BLOCKER
fi

# Check user.name configured
GIT_NAME=$(git config --get user.name || true)
if [[ -z "$GIT_NAME" ]]; then
  echo "[FAIL] git user.name not configured"
  echo "  Run: git config --global user.name \"Your Name\""
  # BLOCKER
fi

# Check user.email configured
GIT_EMAIL=$(git config --get user.email || true)
if [[ -z "$GIT_EMAIL" ]]; then
  echo "[FAIL] git user.email not configured"
  echo "  Run: git config --global user.email \"you@example.com\""
  # BLOCKER
else
  echo "[PASS] git $GIT_VERSION (user: $GIT_NAME <$GIT_EMAIL>)"
fi
```

**If any prerequisite fails**: Stop and show all failures with fix instructions. Do not proceed to next steps.

### 2. Check Beads Directory

Detect worktree context and verify beads is initialized.

```bash
# Detect if in worktree
GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
GIT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null)

if [[ "$GIT_COMMON_DIR" != ".git" && "$GIT_COMMON_DIR" != "$GIT_TOPLEVEL/.git" ]]; then
  # In worktree - use parent repo's .beads/
  REPO_ROOT=$(dirname "$GIT_COMMON_DIR")
  BEADS_DIR="$REPO_ROOT/.beads"
  echo "[INFO] Worktree detected, using parent repo: $REPO_ROOT"
else
  # In main repo
  REPO_ROOT="$GIT_TOPLEVEL"
  BEADS_DIR="$REPO_ROOT/.beads"
fi

# Check if .beads/ exists
if [[ ! -d "$BEADS_DIR" ]]; then
  echo "[FAIL] Beads not initialized at $BEADS_DIR"
  echo "  Initialize? Run: bd init"
  # Prompt user - if they confirm, run bd init
  # If declined, this is a BLOCKER
fi

# Validate with smoke test
if ! bd list --status=open &>/dev/null; then
  echo "[FAIL] Beads database invalid or corrupted"
  echo "  Try: rm -rf $BEADS_DIR && bd init"
  # BLOCKER
else
  echo "[PASS] Beads initialized at $BEADS_DIR"
fi

# Check .gitignore excludes local files
GITIGNORE="$REPO_ROOT/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -Fq '.beads/*.db' "$GITIGNORE" 2>/dev/null; then
    echo "[WARN] .gitignore missing: .beads/*.db"
    echo "  Add to prevent committing local database"
  fi
  if ! grep -Fq '.beads/*.log' "$GITIGNORE" 2>/dev/null; then
    echo "[WARN] .gitignore missing: .beads/*.log"
    echo "  Add to prevent committing daemon logs"
  fi
fi
```

### 3. Check Daemon Status

Daemon issues are **WARNINGS** - setup can continue but sync won't work automatically.

```bash
# Sync before any daemon changes (protect in-flight data)
if ! bd sync 2>&1; then
  echo "[WARN] Pre-restart sync failed - changes may not be saved"
fi

# Check daemon status (use deprecated flag for parseable format)
DAEMON_STATUS=$(bd daemon --status 2>&1)

if echo "$DAEMON_STATUS" | grep -q "Daemon is running"; then
  # Daemon running - check flags
  HAS_COMMIT=$(echo "$DAEMON_STATUS" | grep -q "Auto-Commit: true" && echo "yes" || echo "no")
  HAS_PUSH=$(echo "$DAEMON_STATUS" | grep -q "Auto-Push: true" && echo "yes" || echo "no")
  DAEMON_PID=$(echo "$DAEMON_STATUS" | grep -oE 'PID [0-9]+' | grep -oE '[0-9]+')

  if [[ "$HAS_COMMIT" == "yes" && "$HAS_PUSH" == "yes" ]]; then
    echo "[PASS] Daemon running (PID $DAEMON_PID) with auto-commit and auto-push"
  else
    echo "[WARN] Daemon running but missing flags (commit=$HAS_COMMIT, push=$HAS_PUSH)"
    echo "  Restarting daemon with correct flags..."

    # Stop and restart
    bd daemon --stop 2>/dev/null || true
    sleep 0.5

    if bd daemon --start --auto-commit --auto-push 2>/dev/null; then
      NEW_STATUS=$(bd daemon --status 2>&1)
      NEW_PID=$(echo "$NEW_STATUS" | grep -oE 'PID [0-9]+' | grep -oE '[0-9]+')
      echo "[PASS] Daemon restarted (PID $NEW_PID) with correct flags"
    else
      echo "[WARN] Daemon restart failed"
      echo "  Check: $BEADS_DIR/daemon.log"
      echo "  Manual fix: bd daemon --start --auto-commit --auto-push"
      # WARN - continue but note the issue
    fi
  fi
else
  # Daemon not running - start it
  echo "[INFO] Daemon not running, starting..."

  if bd daemon --start --auto-commit --auto-push 2>/dev/null; then
    NEW_STATUS=$(bd daemon --status 2>&1)
    NEW_PID=$(echo "$NEW_STATUS" | grep -oE 'PID [0-9]+' | grep -oE '[0-9]+')
    echo "[PASS] Daemon started (PID $NEW_PID) with auto-commit and auto-push"
  else
    echo "[WARN] Could not start daemon"
    echo "  Check: $BEADS_DIR/daemon.log"
    echo "  Manual fix: bd daemon --start --auto-commit --auto-push"
    # WARN - continue but note the issue
  fi
fi
```

### 4. Check Remote and Sync Branch

Remote issues are **BLOCKERS** - beads sync requires push access.

```bash
# Check origin remote exists
ORIGIN_URL=$(git remote get-url origin 2>/dev/null)
if [[ -z "$ORIGIN_URL" ]]; then
  echo "[FAIL] No 'origin' remote configured"
  echo "  Run: git remote add origin <your-repo-url>"
  # BLOCKER
fi

# Test push access with dry-run
PUSH_ERR=$(git push --dry-run origin HEAD 2>&1)
if [[ $? -ne 0 ]]; then
  echo "[FAIL] Cannot push to origin"
  echo "  Error: $PUSH_ERR"
  echo "  Check SSH keys or HTTPS credentials"
  # BLOCKER
fi

# Check if util/beads-sync branch exists on remote
SYNC_BRANCH="util/beads-sync"
if git ls-remote --heads origin "$SYNC_BRANCH" 2>/dev/null | grep -q "$SYNC_BRANCH"; then
  echo "[PASS] Remote sync branch exists: $SYNC_BRANCH"
else
  echo "[INFO] Creating remote sync branch: $SYNC_BRANCH"

  # Create and push the branch
  BRANCH_ERR=$(git push origin HEAD:refs/heads/$SYNC_BRANCH 2>&1)
  if [[ $? -eq 0 ]]; then
    # Verify it was created
    if git ls-remote --heads origin "$SYNC_BRANCH" 2>/dev/null | grep -q "$SYNC_BRANCH"; then
      echo "[PASS] Created remote sync branch: $SYNC_BRANCH"
    else
      echo "[FAIL] Branch creation could not be verified"
      echo "  Manual fix: git push origin HEAD:refs/heads/$SYNC_BRANCH"
      # BLOCKER
    fi
  else
    echo "[FAIL] Could not create sync branch"
    echo "  Error: $BRANCH_ERR"
    # BLOCKER
  fi
fi
```

### 5. Check Plugin Enablement

Plugin issues are **WARNINGS** - kas workflow works but hooks won't auto-run.

```bash
SETTINGS_FILE="$REPO_ROOT/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "[WARN] No .claude/settings.json found"
  echo "  kas plugin not enabled - hooks won't auto-run"
  echo "  Create settings.json and enable plugin? (prompt user)"
  # If user confirms, create:
  # mkdir -p "$REPO_ROOT/.claude"
  # echo '{"enabledPlugins":{"kas@kas-claude-plugins":true}}' > "$SETTINGS_FILE"
  # WARN - continue but note the issue
else
  # Check if kas plugin is enabled (use jq if available, fallback to grep)
  if command -v jq &>/dev/null; then
    ENABLED=$(jq -r '.enabledPlugins["kas@kas-claude-plugins"] // false' "$SETTINGS_FILE" 2>/dev/null)
    if [[ "$ENABLED" == "true" ]]; then
      echo "[PASS] kas plugin enabled"
    else
      echo "[WARN] kas plugin not enabled in settings.json"
      echo "  Hooks won't auto-run on session start"
      echo "  Enable plugin? (prompt user)"
      # WARN - continue but note the issue
    fi
  else
    # Fallback: check for pattern on same/adjacent lines
    if grep -q '"kas@kas-claude-plugins"[[:space:]]*:[[:space:]]*true' "$SETTINGS_FILE"; then
      echo "[PASS] kas plugin enabled"
    else
      echo "[WARN] kas plugin not enabled in settings.json"
      echo "  Hooks won't auto-run on session start"
      echo "  Enable plugin? (prompt user)"
      # WARN - continue but note the issue
    fi
  fi
fi

# To enable kas plugin, settings.json needs:
# {
#   "enabledPlugins": {
#     "kas@kas-claude-plugins": true
#   }
# }
```

### 6. Show Summary

Aggregate results and provide final verdict.

```
## Setup Summary

| Check | Status |
|-------|--------|
| bd CLI | [PASS/FAIL] |
| gh CLI | [PASS/FAIL] |
| git config | [PASS/FAIL] |
| Beads directory | [PASS/FAIL] |
| Remote access | [PASS/FAIL] |
| Daemon | [PASS/WARN] |
| Plugin enabled | [PASS/WARN] |
```

**Verdict logic:**

- Any `[FAIL]` → "Setup incomplete. Fix the issues above before using kas workflow."
- Only `[WARN]` → "Ready for kas workflow (with warnings). Optional fixes noted above."
- All `[PASS]` → "Ready for kas workflow."

**Severity mapping:**

| Check | Severity | Reason |
|-------|----------|--------|
| Prerequisites (bd, gh, git) | BLOCKER | Cannot function without these |
| Beads directory | BLOCKER | Core data storage |
| Remote access | BLOCKER | Cannot sync without push access |
| Daemon | WARN | Can be started manually |
| Plugin enabled | WARN | Hooks won't auto-run but workflow works |

## Rules

- Prerequisites are BLOCKERS - must all pass before continuing
- Report versions only on failure (keep success output minimal)
- Idempotent: safe to run multiple times
- Non-destructive: never modify without user confirmation

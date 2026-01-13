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
BD_VERSION=$(bd --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
if [[ -z "$BD_VERSION" ]]; then
  echo "[FAIL] Could not determine bd version"
  # BLOCKER
fi

# Compare versions (0.5.0 minimum)
BD_MAJOR=$(echo "$BD_VERSION" | cut -d. -f1)
BD_MINOR=$(echo "$BD_VERSION" | cut -d. -f2)
if [[ "$BD_MAJOR" -lt 1 && "$BD_MINOR" -lt 5 ]]; then
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
GH_VERSION=$(gh --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
GH_MAJOR=$(echo "$GH_VERSION" | cut -d. -f1)
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
GIT_VERSION=$(git --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)
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

*Implemented in kas-plugins-26z*

### 3. Check Daemon Status

*Implemented in kas-plugins-x1z*

### 4. Check Remote and Sync Branch

*Implemented in kas-plugins-rx8*

### 5. Check Hooks Configuration

*Implemented in kas-plugins-ui3*

### 6. Show Summary

*Implemented in kas-plugins-l7s*

## Rules

- Prerequisites are BLOCKERS - must all pass before continuing
- Report versions only on failure (keep success output minimal)
- Idempotent: safe to run multiple times
- Non-destructive: never modify without user confirmation

#!/bin/bash
# Ensure beads daemon runs with correct flags
# Always exits 0 - never blocks session startup

set +e  # Don't exit on errors

# Check if bd command exists
if ! command -v bd &>/dev/null; then
  exit 0  # Silent exit - beads not installed
fi

# Check if in a beads-enabled directory
if [ ! -d ".beads" ]; then
  exit 0  # Silent exit - not a beads project
fi

# Check daemon status
if status=$(bd daemon --status 2>&1); then
  # Daemon running - check if flags are correct
  if echo "$status" | grep -q "Auto-Commit: true" && echo "$status" | grep -q "Auto-Push: true"; then
    exit 0  # Already running with correct flags
  fi
  # Wrong flags - stop and restart
  bd daemon --stop 2>/dev/null || true
  sleep 0.5
fi

# Start with correct flags (suppress output, ignore errors)
bd daemon --start --auto-commit --auto-push >/dev/null 2>&1 || true

exit 0

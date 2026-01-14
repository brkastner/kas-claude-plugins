---
description: Run code review using kas-code-reviewer agent
---

# /kas:review-code - Code Quality Review

Run a ruthless code review channeling Linus Torvalds philosophy.

## Workflow

### 1. Identify scope

```bash
git status
git diff --stat
```

If no changes, report "Nothing to review" and stop.

### 2. Read agent instructions

Read `agents/code-reviewer.md` (relative to plugin root) and apply the review philosophy, checklist, and output format defined there.

### 3. Execute review

Review the changes following the agent's:
- Review philosophy (simplicity, correctness, performance, readability, error handling)
- Severity levels (Critical 91-100, High 71-90, Medium 41-70, Low 1-40)
- Review checklist
- Output format

### 4. Return findings

Provide structured output with:
- Overall assessment: APPROVED / NEEDS CHANGES / REJECTED
- Issues by severity with file:line references
- Positive observations

## Rules

- Read-only: Never edit files
- Return structured findings, do not apply fixes
- Address all Critical and High issues before approving

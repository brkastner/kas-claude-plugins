---
description: Run reality assessment using project-reality-manager agent
---

# /kas:review-reality - Reality Assessment

Validate claimed completions with extreme skepticism. Cut through optimistic status reports.

## Workflow

### 1. Identify scope

```bash
git status
git diff --stat
```

If no changes, report "Nothing to assess" and stop.

### 2. Read agent instructions

Read `agents/project-reality-manager.md` (relative to plugin root) and apply the reality assessment approach defined there.

### 3. Execute assessment

Assess with skepticism:
- What actually works when tested vs what merely exists in code
- Functions that exist but don't work end-to-end
- Missing error handling that makes features unusable
- Gaps between claimed and actual completion

### 4. Return findings

Provide structured output with:
- Honest assessment of current functional state
- Gap analysis with severity (Critical / High / Medium / Low)
- Prioritized action plan with testable completion criteria
- Prevention recommendations

## Rules

- Read-only: Never edit files
- Verify before trusting - test actual functionality
- Zero tolerance for optimistic status reports
- Return findings, do not apply fixes

---
description: Comprehensive code verification with parallel review agents
---

# /kas:verify - Verify Implementation

Run all review agents in parallel, combine findings, then run code-simplifier if passing.

## Workflow

### 1. Check scope

```bash
git status
git diff --stat
```

If no changes, report "Nothing to verify" and stop.

### 2. Launch parallel reviews

Use the Task tool to launch **six general-purpose agents in parallel** (single message, multiple tool calls):

**Agent 1 - Code Review (kas):**
```
"Run code review on the current git changes.
Read agent instructions at /home/kas/dev/kas-plugins/agents/code-reviewer.md
Return structured findings with severity levels and overall assessment (APPROVED/NEEDS CHANGES/REJECTED)."
```

**Agent 2 - Reality Assessment (kas):**
```
"Run reality assessment on the current git changes.
Read agent instructions at /home/kas/dev/kas-plugins/agents/project-reality-manager.md
Return gap analysis and functional state assessment."
```

**Agent 3 - Silent Failure Hunter (pr-review-toolkit):**
```
"Check for silent failures in error handling.
Look for: empty catch blocks, swallowed exceptions, missing error propagation, try/catch without proper handling.
Return findings with severity levels."
```

**Agent 4 - Comment Analyzer (pr-review-toolkit):**
```
"Analyze comments, docstrings, and documentation in the changes.
Check for: outdated comments, missing docs on public APIs, misleading comments, TODO/FIXME items.
Return findings with severity levels."
```

**Agent 5 - Type Design Analyzer (pr-review-toolkit):**
```
"Review type definitions, interfaces, and schemas in the changes.
Check for: overly permissive types, missing null checks, inconsistent naming, type safety issues.
Return findings with severity levels."
```

**Agent 6 - Test Analyzer (pr-review-toolkit):**
```
"Analyze test coverage for the changes.
Check for: missing tests, inadequate assertions, untested edge cases, test quality.
Return findings with coverage assessment."
```

### 3. Combine findings

After all agents return, merge results into categories:

**Code Quality** (code-reviewer + silent-failure-hunter):
- Critical/High/Medium/Low issues
- Error handling gaps

**Documentation** (comment-analyzer):
- Comment quality issues
- Missing documentation

**Type Safety** (type-design-analyzer):
- Type design issues
- Schema problems

**Test Coverage** (test-analyzer):
- Coverage gaps
- Test quality issues

**Reality Assessment** (project-reality-manager):
- Functional state
- Gap analysis

**Overall Verdict** using worst-wins logic:

| Condition | Verdict |
|-----------|---------|
| All agents pass, no critical/high issues | VERIFIED |
| Any agent has medium issues only | NEEDS CHANGES |
| Any agent has critical/high issues | BLOCKED |

### 4. If VERIFIED: Run code-simplifier

Only if verdict is VERIFIED, launch one more agent:

**Agent 7 - Code Simplifier (pr-review-toolkit):**
```
"Review the changes for simplification opportunities.
Look for: over-engineering, unnecessary abstractions, code that could be simpler.
Return suggestions (these are optional improvements, not blockers)."
```

Present simplification suggestions separately - these don't change the verdict.

### 5. Present and wait

Summarize combined findings and ask for approval:
- If VERIFIED: "All checks pass. [Simplification suggestions if any]. Proceed?"
- If NEEDS CHANGES: "Issues found. Approve fixes?"
- If BLOCKED: "Critical blockers. How to proceed?"

Do NOT apply fixes automatically.

## Rules

- All 6 primary agents MUST complete before providing verdict
- Use worst-wins logic (conservative approach)
- code-simplifier only runs after VERIFIED verdict
- Never apply fixes without user approval
- Empty diff = exit early, don't launch agents

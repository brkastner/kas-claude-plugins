---
description: Tiered code verification with smart agent selection
---

# /kas:verify - Verify Implementation

Tiered verification with early-exit. Only runs agents relevant to the changes.

## Workflow

### 1. Check scope and determine relevant agents

```bash
git status
git diff --stat
git diff
```

If no changes, report "Nothing to verify" and stop.

**Analyze the diff to determine which agents are relevant:**

| Change Pattern | Agents to Run |
|----------------|---------------|
| Any code changes | code-reviewer (always) |
| try/catch, error handling, catch blocks | + silent-failure-hunter |
| Comments, docstrings, JSDoc, `//`, `/*`, `"""` | + comment-analyzer |
| Type definitions, interfaces, schemas, generics | + type-design-analyzer |
| Test files, describe/it/test blocks | + pr-test-analyzer |

**Skip agents that have no relevant changes.** For example:
- Markdown-only changes → skip all static analysis, proceed to Tier 2
- Config file changes → code-reviewer only
- Type definition changes → code-reviewer + type-design-analyzer

### 2. Tier 1: Static Analysis (parallel, only relevant agents)

Launch **only the relevant agents** in parallel using the Task tool.

**Agent - Code Review (kas):** *(run if any code changes)*
```
"Run code review on the current git changes.
Read agent instructions at agents/code-reviewer.md (relative to plugin root)
Return structured findings with severity levels and overall assessment (APPROVED/NEEDS CHANGES/REJECTED)."
```

**Agent - Silent Failure Hunter (pr-review-toolkit):** *(run if error handling changes)*
```
"Check for silent failures in error handling.
Look for: empty catch blocks, swallowed exceptions, missing error propagation, try/catch without proper handling.
Return findings with severity levels."
```

**Agent - Type Design Analyzer (pr-review-toolkit):** *(run if type/interface changes)*
```
"Review type definitions, interfaces, and schemas in the changes.
Check for: overly permissive types, missing null checks, inconsistent naming, type safety issues.
Return findings with severity levels."
```

**Agent - Comment Analyzer (pr-review-toolkit):** *(run if comments/docs changes)*
```
"Analyze comments, docstrings, and documentation in the changes.
Check for: outdated comments, missing docs on public APIs, misleading comments, TODO/FIXME items.
Return findings with severity levels."
```

**Agent - Test Analyzer (pr-review-toolkit):** *(run if test file changes)*
```
"Analyze test coverage for the changes.
Check for: missing tests, inadequate assertions, untested edge cases, test quality.
Return findings with coverage assessment."
```

**Tier 1 Exit Conditions:**

| Condition | Verdict | Action |
|-----------|---------|--------|
| Any critical/high issues | BLOCKED | Stop, present findings |
| Any medium issues | NEEDS CHANGES | Stop, present findings |
| All clean (or no agents ran) | Continue | Proceed to Tier 2 |

### 3. Tier 2: Dynamic Assessment (only if Tier 1 clean)

Launch **one agent**:

**Agent - Reality Assessment (kas):**
```
"Run reality assessment on the current git changes.
Read agent instructions at agents/project-reality-manager.md (relative to plugin root)
Return gap analysis and functional state assessment."
```

**Tier 2 Exit Conditions:**

| Condition | Verdict | Action |
|-----------|---------|--------|
| Gaps or issues found | NEEDS CHANGES | Stop, present findings |
| Severe gaps | BLOCKED | Stop, present findings |
| Clean | VERIFIED | Proceed to Tier 3 |

### 4. Tier 3: Polish (only if VERIFIED)

Launch **one agent**:

**Agent - Code Simplifier (pr-review-toolkit):**
```
"Review the changes for simplification opportunities.
Look for: over-engineering, unnecessary abstractions, code that could be simpler.
Return suggestions (these are optional improvements, not blockers)."
```

Simplification suggestions are optional - they don't change the VERIFIED verdict.

### 5. Present and wait

Report which agents were run and why, then summarize findings:

- **VERIFIED** (reached Tier 3): "All checks pass. [Simplification suggestions if any]. Proceed?"
- **NEEDS CHANGES** (Tier 1 or 2): "Issues found at [tier]. Approve fixes?"
- **BLOCKED** (Tier 1 or 2): "Critical blockers at [tier]. How to proceed?"

Do NOT apply fixes automatically.

## Rules

- Analyze diff FIRST to determine relevant agents
- Skip agents with no relevant changes (saves tokens)
- Tier 1 agents run in parallel for speed
- Tier 2 only runs if Tier 1 has zero issues
- Tier 3 only runs if Tier 2 returns VERIFIED
- Never apply fixes without user approval
- Empty diff = exit early, don't launch agents

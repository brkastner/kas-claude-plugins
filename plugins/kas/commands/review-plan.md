---
description: Review implementation plan using plan-reviewer agent
---

Launch the plan-reviewer agent to evaluate the current implementation plan.

## Workflow

1. **Identify the plan to review**
   - Check conversation context for recent plan
   - Look for plan files in `.claude/plans/`

2. **Launch plan-reviewer agent**
   Use the Task tool to invoke the plan-reviewer agent with the plan content.

3. **Summarize findings**
   After agent returns, provide a concise summary of:
   - Overall assessment (APPROVED / NEEDS REVISION / BLOCKED)
   - Critical issues (must fix)
   - High priority issues
   - Recommendations

4. **Wait for user approval**
   Do NOT proceed to task-splitter or implementation without explicit user approval.

# /kas:start - Structured Planning Workflow

Entry point for creating implementation plans with proper workflow enforcement.

## Usage

```bash
/kas:start                    # Start planning for current task
/kas:start "Add user auth"    # Start with specific task description
```

## Workflow

### Step 1: Check Beads Context

Before planning, gather context from existing work:

```bash
# Check for open issues that might be related
bd list --status=open

# Check for in-progress work
bd list --status=in_progress
```

If relevant issues found, include their context in the exploration phase.

**If beads not initialized:** Warn user and suggest running `/kas:setup` first. Continue without beads context if user chooses.

### Step 2: Enter Plan Mode

If not already in plan mode, use the **EnterPlanMode tool** to request plan mode from user.

**If already in plan mode:** Skip this step, continue with current plan file.

### Step 3: Explore Phase

Launch Explore agents (1-3 based on scope) to gather codebase context:
- Existing implementations and patterns
- Related components and dependencies
- Testing patterns

Include beads context (from Step 1) in agent prompts when relevant.

**On explore failure:** Report findings so far, ask user how to proceed.

### Step 4: Design Phase

Launch Plan agent with:
- Exploration findings from Step 3
- User requirements
- Beads context (related issues, prior decisions)

### Step 5: Review & Finalize

1. Read critical files identified by agents
2. Validate alignment with user intent
3. Ask clarifying questions via AskUserQuestion if needed
4. Write final plan to plan file

### Step 6: Review Agents (Auto-triggered)

After plan is written, ALWAYS run these agents before ExitPlanMode:

1. **plan-reviewer** - Check for security gaps, design flaws
2. **task-splitter** - Decompose into beads issues, output bd commands

### Step 7: Exit Plan Mode

Call ExitPlanMode to present to user:
- The plan
- Review findings
- bd create commands

## Error Handling

| Failure | Response |
|---------|----------|
| Beads not initialized | Warn, offer to continue without beads context |
| Already in plan mode | Use existing plan file, continue workflow |
| Explore agent fails | Report partial findings, ask user direction |
| User rejects at review | Ask what to revise, update plan |
| plan-reviewer finds blockers | Show findings, do NOT call ExitPlanMode until resolved |

## Integration Contract (for 3rd Party Skills)

Skills invoking `/kas:start` can depend on:

**Guaranteed after completion:**
- Plan mode was active during planning
- Plan file exists at `.claude/plans/<name>.md`
- plan-reviewer ran (findings available)
- task-splitter ran (bd commands prepared)
- User approved via ExitPlanMode

**Side effects:**
- Beads context loaded if available
- Plan file written
- No issues created yet (user must approve first)

## Rules

- Always check beads context before planning
- Never skip plan-reviewer or task-splitter
- Stop after ExitPlanMode - user clears context before implementation
- If plan-reviewer returns BLOCKED, do not exit plan mode

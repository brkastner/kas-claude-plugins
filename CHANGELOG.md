# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-01-14

### Changed
- **Multi-plugin marketplace structure**: Restructured repository to support multiple plugins
  - kas plugin moved to `plugins/kas/` subdirectory
  - marketplace.json updated with subdirectory source path
  - Repository renamed from `kas-claude-plugin` to `kas-claude-plugins`
- Plugin reference changed from `kas@kas-claude-plugin` to `kas@kas-claude-plugins`

### Added
- CONTRIBUTING.md with guidelines for plugin developers
- Plugin-specific README at `plugins/kas/README.md`
- Documentation of plugin subdirectory verification at `docs/plugin-subdirectory-verification.md`

### Migration
Update your `.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "kas@kas-claude-plugins": true
  }
}
```

## [1.6.0] - 2025-01-13

### Added
- `/kas:setup` - Prepare project for kas workflow
  - Validates prerequisites (bd ≥0.5.0, gh authenticated with repo scope, git ≥2.20.0)
  - Detects worktree context and uses parent repo's .beads/
  - Manages daemon with sync-before-change and auto-restart
  - Verifies remote push access and creates util/beads-sync branch
  - Checks if kas plugin is enabled in target project
  - Shows summary with PASS/FAIL/WARN verdict

### Changed
- CLAUDE.md now includes plugin development context section

## [1.3.0] - 2025-01-09

### Added
- `/kas:verify` now integrates pr-review-toolkit agents:
  - silent-failure-hunter, comment-analyzer, type-design-analyzer, pr-test-analyzer (parallel)
  - code-simplifier (runs after VERIFIED verdict)

### Changed
- `/kas:verify` runs 6 agents in parallel instead of 2

## [1.2.0] - 2025-01-09

### Added
- `/kas:verify` - Orchestrator command that runs code review and reality assessment in parallel
- `/kas:review-code` - Standalone code quality review (Linus Torvalds style)
- `/kas:review-reality` - Standalone reality assessment (skeptical validation)

### Changed
- Commands are now composable: `/kas:verify` uses Task agents to run the standalone commands in parallel

## [1.1.0] - 2025-01-09

### Fixed
- **task-splitter auto-trigger**: Now chains from plan-reviewer output, ensuring it runs before ExitPlanMode
- **plan-reviewer → task-splitter flow**: Added explicit "Next Step" in plan-reviewer output
- **SessionStart hook error**: Made ensure-daemon.sh silent and always exit 0
- **Post-approval workflow**: Stops after beads creation, provides next session prompt for context clearing

### Changed
- task-splitter now runs BEFORE ExitPlanMode (alongside plan-reviewer) instead of after approval
- Implementation must start in fresh context after `/clear`

## [1.0.0] - 2025-01-09

### Added

#### Commands
- `/kas:done` - Complete session, push all changes
- `/kas:save` - Snapshot session for later continuation
- `/kas:next` - Find next available beads issue
- `/kas:merge` - Merge PR to main

#### Agents
- `task-splitter` - Decompose implementation plans into beads issues
- `plan-reviewer` - Review plans for security gaps and design issues
- `code-reviewer` - Ruthless code review channeling Linus Torvalds
- `browser-automation` - Web testing and automation via Claude-in-Chrome
- `project-reality-manager` - Validate claimed task completions

#### Skills
- `browser` - Browser automation skill with subagent delegation pattern

#### Hooks
- SessionStart hook for automatic beads daemon startup

#### Documentation
- Generic CLAUDE.md with workflow instructions
- README with installation and usage
- MIT License

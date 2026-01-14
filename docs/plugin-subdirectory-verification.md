# Plugin Subdirectory Verification Results

## Summary

All critical assumptions about Claude Code plugin subdirectory behavior have been **verified and confirmed** through practical testing.

## Test Setup

Created `plugins/test-plugin/` with:
- `.claude-plugin/plugin.json` - minimal manifest
- `hooks/hooks.json` - SessionStart hook that logs `${CLAUDE_PLUGIN_ROOT}`
- `hooks/scripts/test-root.sh` - script to verify path resolution
- `commands/test.md` - test command
- `agents/test-agent.md` - test agent
- `CLAUDE.md` - test instructions (marker: `SUBDIRECTORY_CLAUDEMD_LOADED`)

Updated `marketplace.json` to include:
```json
{
  "name": "test-plugin",
  "source": "./plugins/test-plugin",
  ...
}
```

## Verification Results

### 1. `${CLAUDE_PLUGIN_ROOT}` Resolution

**Status: VERIFIED**

```
CLAUDE_PLUGIN_ROOT: /path/to/repo/plugins/test-plugin
```

- Resolves to the plugin's source directory, **not** the repository root
- Correct for subdirectory plugins with `"source": "./plugins/test-plugin"`
- Script paths using `${CLAUDE_PLUGIN_ROOT}/...` work correctly

### 2. Hooks Execution

**Status: VERIFIED**

- `hooks/hooks.json` discovered from plugin subdirectory
- SessionStart hook fired correctly
- Script at `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/test-root.sh` executed successfully

### 3. Commands Discovery

**Status: VERIFIED**

- Command at `plugins/test-plugin/commands/test.md` discovered
- Invoking `/test-plugin:test` works correctly
- Response: "Test plugin command discovered successfully from subdirectory!"

### 4. Agents Discovery

**Status: VERIFIED**

- Agent at `plugins/test-plugin/agents/test-agent.md` discovered
- Listed as `test-plugin:test-agent` in available agents
- Task tool can invoke the agent successfully

### 5. CLAUDE.md Loading

**Status: NOT LOADED (Expected)**

- CLAUDE.md in plugin subdirectory is **not** auto-loaded into context
- This is documented behavior - CLAUDE.md is for target project instructions, not plugin distribution
- **Fallback strategy**: Plugin instructions should be in `commands/*.md` or agent prompts

## Implications for Multi-Plugin Marketplace

### What Works

1. Multiple plugins in subdirectories with separate `source` paths
2. Each plugin gets its own isolated `${CLAUDE_PLUGIN_ROOT}`
3. Hooks, commands, and agents are discovered per-plugin
4. Plugin validation (`claude plugin validate`) passes

### What Doesn't Work

1. CLAUDE.md from plugins is not loaded
2. Cross-plugin file sharing via `../` paths (caching copies only source directory)
3. Shared utilities outside plugin source must be duplicated or symlinked

## Fallback Strategies

### For Plugin Instructions (CLAUDE.md limitation)

Since CLAUDE.md isn't loaded from plugins:
- Put workflow instructions in command files (`commands/*.md`)
- Include critical context in agent prompts (`agents/*.md`)
- Document plugin usage in README.md for human reference

### For Shared Utilities

Since cross-plugin paths don't work:
- **Option A**: Symlinks (followed during cache copy)
- **Option B**: Duplicate shared code per plugin
- **Option C**: Keep shared code at repo root (outside plugin source), use as dev-only

## Test Commands

Validate plugin structure:
```bash
claude plugin validate ./plugins/test-plugin
```

Test with `--plugin-dir`:
```bash
claude --plugin-dir ./plugins/test-plugin -p "test command"
```

Check hook execution log:
```bash
cat /tmp/test-plugin-root.log
```

## Conclusion

The multi-plugin subdirectory structure is **fully supported** by Claude Code. The refactor to `plugins/kas/` is safe to proceed.

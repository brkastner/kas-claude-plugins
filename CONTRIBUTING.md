# Contributing to kas-claude-plugins

Guidelines for contributing plugins to this marketplace.

## Repository Structure

```
kas-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # Lists all available plugins
├── plugins/
│   ├── kas/                  # Each plugin in its own directory
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json   # Plugin manifest
│   │   ├── agents/           # Subagent definitions
│   │   ├── commands/         # Slash commands
│   │   ├── hooks/            # Hook configuration
│   │   ├── skills/           # Agent skills
│   │   └── README.md         # Plugin documentation
│   └── your-plugin/
│       └── ...
├── CONTRIBUTING.md           # This file
└── README.md                 # Marketplace documentation
```

## Adding a New Plugin

### 1. Create Plugin Directory

```bash
mkdir -p plugins/your-plugin/{.claude-plugin,agents,commands,hooks,skills}
```

### 2. Create Plugin Manifest

`plugins/your-plugin/.claude-plugin/plugin.json`:
```json
{
  "name": "your-plugin",
  "description": "What your plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "url": "https://github.com/yourusername"
  },
  "repository": "https://github.com/brkastner/kas-claude-plugins",
  "license": "MIT",
  "keywords": ["relevant", "keywords"]
}
```

### 3. Register in Marketplace

Add to `.claude-plugin/marketplace.json`:
```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "description": "Brief description",
      "version": "1.0.0",
      "source": "./plugins/your-plugin",
      "category": "productivity"
    }
  ]
}
```

### 4. Validate

```bash
claude plugin validate ./plugins/your-plugin
```

## Plugin Components

### Commands (`commands/*.md`)

Slash commands that users invoke directly.

```markdown
# /your-plugin:command-name - Brief description

Detailed instructions for Claude when this command is invoked.

## Workflow

1. Step one
2. Step two
```

### Agents (`agents/*.md`)

Subagents invoked via the Task tool.

```markdown
# Agent Name

Description of what this agent does.

## When to Use

- Scenario A
- Scenario B

## Behavior

Instructions for the agent...
```

### Hooks (`hooks/hooks.json`)

Event handlers that run automatically.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/your-script.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Important**: Always use `${CLAUDE_PLUGIN_ROOT}` for paths in hooks.

### Skills (`skills/*/SKILL.md`)

Specialized capabilities with triggers and behaviors.

## Best Practices

### Paths

- Always use `${CLAUDE_PLUGIN_ROOT}` in hooks and scripts
- Plugins are cached; absolute paths won't work after installation

### Scripts

- Make scripts executable: `chmod +x hooks/scripts/*.sh`
- Exit cleanly; don't block on errors
- Keep hooks fast (< 10s timeout recommended)

### Documentation

- Include README.md in your plugin directory
- Document all commands, agents, and hooks
- Provide usage examples

### Testing

Test your plugin before submitting:

```bash
# Validate manifest
claude plugin validate ./plugins/your-plugin

# Test with --plugin-dir
claude --plugin-dir ./plugins/your-plugin -p "test your commands"
```

## Pull Request Process

1. Fork the repository
2. Create your plugin in `plugins/your-plugin/`
3. Validate the plugin manifest
4. Add entry to marketplace.json
5. Test installation and all features
6. Submit PR with:
   - Description of what the plugin does
   - List of commands/agents provided
   - Any prerequisites

## Code of Conduct

- Keep plugins focused and well-documented
- Don't duplicate existing functionality
- Respect user privacy (no telemetry without consent)
- Handle errors gracefully

## Questions?

Open an issue at https://github.com/brkastner/kas-claude-plugins/issues

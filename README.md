# kas-claude-plugins

A marketplace of Claude Code plugins for workflow automation, task tracking, and code review.

## Available Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| [kas](./plugins/kas/) | Workflow automation with beads task tracking, session management, and code review | 1.7.0 |

## Installation

### Add the Marketplace

```bash
# Add marketplace
claude plugin marketplace add brkastner/kas-claude-plugins

# List available plugins
claude plugin marketplace list kas-claude-plugins
```

### Install a Plugin

```bash
# Install kas plugin
claude plugin install kas@kas-claude-plugins
```

### Local Development

```bash
# Clone the repo
git clone https://github.com/brkastner/kas-claude-plugins.git

# Use specific plugin with Claude Code
claude --plugin-dir ./plugins/kas
```

## Plugin Documentation

Each plugin has its own README with detailed usage instructions:

- [kas plugin](./plugins/kas/README.md) - Workflow automation with beads, sessions, and code review

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on adding new plugins.

## License

MIT

# Solana Agent Ops

This repo is a skill package for Solana AI Kit / Claude Code / Codex.

It gives an agent the operational pieces it needs to run a Solana setup safely:
- identity with Squads v4
- funding with caps
- TEE signer deployment
- monitoring and kill switch
- agent-to-agent payments
- security rules

## Install

Run the standard installer:

```bash
./install.sh
```

Or use the custom installer if you want to choose what gets installed:

```bash
./install-custom.sh
```

## What gets installed

- `skill/` for the main skill router and focused skill files
- `agents/` for specialized subagents
- `commands/` for workflow commands
- `rules/` for always-on safety rules
- `CLAUDE.md` for local Claude Code guidance

## Files to read first

- [skill/SKILL.md](skill/SKILL.md)
- [commands/README.md](commands/README.md)
- [rules/README.md](rules/README.md)

## Purpose

Use this repo when you want a coding agent to help with Solana agent operations, not general Solana program development.

## License

MIT

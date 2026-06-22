# Solana Agent Ops

This repo is a skill package for Solana AI Kit, Claude Code, and Codex.

It tells an agent how to run Solana operations safely. It covers:
- Squads v4 identity and roles
- funding with caps and a circuit breaker
- TEE signer deployment
- monitoring and kill switch
- agent-to-agent payments
- security rules

## What problem it solves

Solana agents can do useful work, but they still need a safe way to exist in production.
This repo gives them the operational rules and workflows for that. It helps with:
- keeping the agent's identity stable
- keeping keys out of `.env` and logs
- keeping spending bounded
- stopping the agent when something goes wrong
- handling small payments without giving away full treasury control

## Install

From the repo root, run the standard installer:

```bash
./install.sh
```

Use the custom installer if you want to choose what gets installed or where it goes:

```bash
./install-custom.sh
```

## What gets installed

- `skill/` for the main skill router and focused skill files
- `agents/` for specialized subagents
- `commands/` for workflow commands
- `rules/` for always-on safety rules
- `CLAUDE.md` for local Claude Code guidance

## Read first

- [skill/SKILL.md](skill/SKILL.md)
- [commands/README.md](commands/README.md)
- [rules/README.md](rules/README.md)

## Purpose

Use this repo when you want a coding agent to help with Solana agent operations, not general Solana program development.

## License

MIT

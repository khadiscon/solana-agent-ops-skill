# Agents

Four focused subagents for autonomous Solana agent operations. Each has a clear remit, a recommended model, and the same hard line: never store a key in an env var/file/log, never skip simulation, never over-promise security.

| Agent | Model | Purpose |
| --- | --- | --- |
| **agent-architect** | opus | Designs the ops architecture: identity, roles, funding tiers, deployment topology, kill switch |
| **ops-engineer** | sonnet | Implements Squads config, funding loops, TEE deployment, monitoring, and payments |
| **security-auditor** | opus | Reviews designs and code against the non-negotiables before mainnet |
| **solana-guide** | sonnet | Explains concepts and writes docs for builders |

All agents load `skill/SKILL.md` first and follow its progressive routing.

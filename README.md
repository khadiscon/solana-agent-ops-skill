# Solana Agent Ops Skill

> Production operations for autonomous AI agents on Solana — identity, funding, confidential execution, monitoring, and agent-to-agent payments. The missing layer beneath the [Solana Agent Kit](https://github.com/sendaifun/solana-agent-kit).

> **Layer**: operational/ops, not program development. **Defers to**: [`solana-dev-skill`](https://github.com/solana-foundation/solana-dev-skill) for program development, RPC/client primitives, and general security checklists — this skill doesn't duplicate them. **Complements**: the `solana-agent-kit` library (actions) — a runtime dependency, not a sibling skill.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## The problem

The Solana Agent Kit taught agents to **act** — swap, stake, transfer, mint, deploy. But an agent that can move money and runs unattended raises five questions no actions library answers:

- **Who is it on-chain?** A raw keypair is a single point of total failure.
- **How does it stay funded** without becoming a faucet you can drain?
- **Where do its keys live** so a hacked server doesn't mean a stolen wallet?
- **How do you know it's healthy** — and stop it fast when it isn't?
- **How does it pay other agents** safely?

Get these wrong and “autonomous agent” becomes “unsupervised wallet drainer.” This skill is the **operational infrastructure layer** that gets them right.

## What you get

| Capability | Pattern |
| --- | --- |
| **Identity & control** | Squads v4 smart account as a stable, governable identity; agent as Proposer; per-token spending limits for routine autonomy |
| **Self-funding** | Threshold top-ups with rate limits, caps, and a latching circuit breaker; treasury-gated large refills |
| **Confidential execution** | Keys generated and sealed inside a TEE (Marlin Oyster / Phala dstack), gated by verified remote attestation |
| **Monitoring & safety** | Helius webhooks + read-only health checks + a tested on-chain kill switch |
| **M2M payments** | Agent-to-agent payments from simple transfers to escrow and streaming |

Every pattern is **simulate-first, least-privilege, and bounded by design** — see `skill/security-principles.md`.

## How it fits

```
        Your agent's logic / goals
                 │
   solana-dev-skill  →  program development, RPC/client primitives
                 │       (defer here for anything not agent-ops)
                 │
   Solana Agent Kit  →  WHAT the agent can do (actions; a library, not a skill)
                 │
   Solana Agent Ops  →  HOW it runs safely in production
   (this skill)         identity · funding · keys · monitoring · payments
                 │
              Solana
```

This skill is **complementary**, not a replacement: keep using `solana-dev-skill` for program/client work, the Agent Kit for actions, and this skill for the operational guarantees around them.

## Install

```bash
git clone https://github.com/<your-org>/solana-agent-ops-skill.git
cd solana-agent-ops-skill
./install.sh          # standard install (use -y to skip prompts)
```

For selective installs (choose location and which components):

```bash
./install-custom.sh
```

| Installer | Use when |
| --- | --- |
| `install.sh` | You want the full skill in the default location (`~/.claude/`) |
| `install-custom.sh` | You want to pick personal/project/custom location or install only some of skill/agents/commands/rules |

The installer copies `skill/` → `~/.claude/skills/solana-agent-ops` and the `agents/`, `commands/`, and `rules/` folders into your Claude config.

## How it works: progressive loading

The skill is **token-efficient by design**. `skill/SKILL.md` is a lightweight router; it loads only the knowledge file a task actually needs. You never pay for the whole skill to answer one question.

```
skill/SKILL.md  →  reads the task  →  loads just squads-identity.md (for example)
```

Each file opens with a `> **Load when:**` line so routing is unambiguous.

## Usage examples

> “Set up my trading agent's on-chain identity.” → `/setup-squad` — creates a Squads v4 smart account, agent as Proposer, a daily USDC spending limit.
>
> “Keep it funded but cap the risk.” → `/fund-agent` — auto top-ups under hard caps with a latching breaker; large refills become treasury proposals.
>
> “Make sure its keys can't be stolen.” → `/deploy-tee` — in-enclave keygen on Marlin Oyster or Phala, attestation-gated before funding.
>
> “Is this safe to ship to mainnet?” → `/audit-agent` — reviews against the non-negotiables and returns a go/no-go.

## Repository structure

```
solana-agent-ops-skill/
├── README.md
├── install.sh / install-custom.sh
├── CLAUDE.md                  # guardrails + routing cheat-sheet
├── skill/
│   ├── SKILL.md               # progressive-loading router
│   ├── squads-identity.md     # identity, roles, spending limits
│   ├── self-funding.md        # bounded auto top-ups + treasury tier
│   ├── tee-deployment.md      # Marlin Oyster / Phala + attestation
│   ├── m2m-payments.md        # agent-to-agent payments
│   ├── monitoring-patterns.md # Helius webhooks + kill switch
│   ├── security-principles.md # the non-negotiables + threat model
│   └── resources.md           # 2026 stack links
├── agents/                    # architect · ops-engineer · auditor · guide
├── commands/                  # setup-squad · fund-agent · deploy-tee · monitor-agent · audit-agent
└── rules/                     # always-on key-mgmt, tx-safety, ops conventions
```

## Safety culture (non-negotiable)

1. **Simulate before send** — every state-changing transaction.
2. **Least privilege** — agent is a Proposer with a tight spending limit, never `Permissions.all()`.
3. **Bound every loop** — rate limits, caps, latching circuit breakers.
4. **Keys never touch env vars, disk, or logs** — generate in-enclave or use a signer service.
5. **Multisig for anything that matters** — the agent proposes; humans release.
6. **No over-promising** — we state real guarantees and their assumptions.

## Default stack (2026)

`@solana/kit` (web3.js 2.x) · `solana-agent-kit` v2 · Squads v4 (`@sqds/multisig`) · Helius (+ MCP) · Marlin Oyster (Intel TDX) / Phala dstack · Node.js 22 LTS · TypeScript 5.6+.

## License

MIT — see [LICENSE](LICENSE). Built for the Solana agent-builder community.

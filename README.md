# Solana Agent Ops

[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE) [![Solana](https://img.shields.io/badge/Solana-black?logo=solana)](https://solana.com) [![Claude Code](https://img.shields.io/badge/Claude_Code-powered-orange)](https://claude.com/claude-code)

**Production-ready operational infrastructure for autonomous Solana agents.** Combines best practices for identity, funding, and security into an agent-optimized, token-efficient configuration.

This skill provides the missing operational layer for AI agents. While other kits teach agents how to *act*, **Solana Agent Ops** teaches them how to *exist safely* in production. It leverages a progressive loading architecture to save tokens and context while enforcing non-negotiable safety standards.

*   **Rules** are loaded only when specific operational tasks are involved.
*   **SKILL.md** acts as a dynamic router to specialized knowledge modules.
*   **Progressive Loading** ensures you only pay for the context you actually use.

## What This Is

A complete operational framework that turns any agentic setup into a production-grade Solana operator with:

*   **4 Specialized Agents**: Architect, Ops Engineer, Security Auditor, and Solana Guide.
*   **5 Workflow Commands**: Setup Squads, Fund Agent, Deploy TEE, Monitor Agent, and Audit Security.
*   **Stack**: `@sqds/multisig` v4, Helius RPC/webhooks, TEEs (Marlin Oyster / Phala dstack), `@solana/web3.js` where required by SDK dependencies, `@solana/kit` (web3.js 2.x) for new RPC patterns.
*   **Progressive Skill Loading**: Context-aware routing that minimizes token overhead.
*   **Safety-First Rules**: Always-on enforcement for key management and transaction safety.


## The Problem

Builders shipping autonomous Solana agents hit the same operational cliff:

| Problem | This skill's answer |
| :--- | :--- |
| **No stable identity.** A bare keypair is the agent — one compromise and everything it owned is gone. | Squads v4 vault PDA is the durable address. The signing keypair is a replaceable member. Compromise the key, revoke the member, add a new one — the identity, balances, and history are untouched. |
| **No funding safety.** Manual top-ups stall the agent; automated top-ups without limits build a drain. | Two-tier funding: micro refills under hard per-action and rolling-window caps with a latching circuit breaker; large refills become treasury proposals a human approves. |
| **No safe place for keys.** Most setups end up with the signing key in `.env` or a Docker image — one leaked log away from total loss. | Keys generated inside a TEE (Marlin Oyster sealed signer or Phala CVM). They never exist in plaintext outside the enclave. |
| **No visibility.** No standard way to know when the agent overspends, misbehaves, or needs to be stopped. | Helius webhooks classify every transaction in real time. The kill switch is on-chain authority revocation — not a process kill, a Squads member removal. |
| **No agent-to-agent payments.** M2M value flows are ad hoc, unaudited, and unbounded. | Four payment patterns (direct, escrow, metered, streaming) all bounded by Squads Spending Limits so no payment can exceed the agent's per-window budget. |

The Solana Agent Kit solves *what agents can do*. This skill solves *how they exist safely in production*.

The Solana Agent Kit solves *what agents can do*. This skill solves *how they exist safely in production* — the ops layer that has been missing from every agentic Solana setup.


## Quick Start

```bash
# Clone and install
git clone https://github.com/khadiscon/solana-agent-ops-skill.git
cd solana-agent-ops-skill
./install.sh

# Selective/Project install
./install-custom.sh
```

### Installation Modes

| Installer | Use Case |
| :--- | :--- |
| `install.sh` | Full install to default Claude config (`~/.claude/`). |
| `install-custom.sh` | Pick custom locations or install specific components (agents/rules/commands). |

## Core Modules (Progressive Loading)

| Module | Purpose | Load When... |
| :--- | :--- | :--- |
| `squads-identity.md` | Identity & Control | Setting up smart accounts, roles, or spending limits. |
| `self-funding.md` | Bounded Funding | Configuring auto top-ups and circuit breakers. |
| `tee-deployment.md` | Confidential Execution | Deploying to Marlin/Phala or handling sealed keys. |
| `monitoring-patterns.md` | Observability | Setting up Helius webhooks or kill switches. |
| `m2m-payments.md` | Agent Payments | Implementing escrow or streaming between agents. |
| `security-principles.md` | Safety Core | Reviewing risks or enforcing non-negotiables. |

## Workflow Commands

The skill provides specialized commands to handle complex ops tasks safely:

*   **`/setup-squad`**: Initialize a Squads v4 identity with bounded spending limits.
*   **`/fund-agent`**: Configure safety-gated automated funding.
*   **`/deploy-tee`**: Provision a TEE enclave and generate sealed signing keys.
*   **`/monitor-agent`**: Set up Helius-powered observability and alerts.
*   **`/audit-agent`**: Run a pre-mainnet security review against the non-negotiables.

## The Non-Negotiables

These safety rules override convenience and are enforced by the `rules/` engine:

1.  **Simulate Before Send**: Every transaction is dry-run before execution.
2.  **Least Privilege**: The agent is a Proposer with a tight spending limit, never an admin.
3.  **Keys Never Leak**: Private keys belong in TEEs or KMS; they never touch `.env` or logs.
4.  **Human in the Loop**: Large treasury moves require explicit human approval via multisig.
5.  **No Hype**: We state real technical guarantees and their assumptions.

## Devnet Validation

The core identity pattern — Squads v4 smart account creation with a Proposer-only agent signer — was validated on Solana devnet.

| Step | Transaction |
| :--- | :--- |
| Squads v4 multisig created | *(run `devnet-test/run.mjs` and paste signature here)* |
| Vault PDA derived | *(paste vault PDA here)* |

To reproduce on devnet: see [`devnet-test/README.md`](devnet-test/README.md).

## How it Fits

```text
   [ Your Agent's Logic ]
             │
   [ Solana Agent Kit ]  →  WHAT it can do (Actions)
             │
   [ Solana Agent Ops ]  →  HOW it runs safely (This Skill)
             │
   [     Solana       ]  →  The Network
```

*Note: For program development (Anchor/Pinocchio) or low-level RPC primitives, this skill defers to [`solana-dev-skill`](https://github.com/solana-foundation/solana-dev-skill).*

## License

MIT

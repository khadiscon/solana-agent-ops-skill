# Solana Agent Ops

[![CI](https://github.com/your-org/solana-agent-ops-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/solana-agent-ops-skill/actions/workflows/ci.yml) [![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/your-org/solana-agent-ops-skill/releases) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE) [![Solana](https://img.shields.io/badge/Solana-black?logo=solana)](https://solana.com) [![Claude Code](https://img.shields.io/badge/Claude_Code-powered-orange)](https://claude.com/claude-code)

**Production-ready operational infrastructure for autonomous Solana agents.** Combines best practices for identity, funding, and security into an agent-optimized, token-efficient configuration.

This skill provides the missing operational layer for AI agents. While other kits teach agents how to *act*, **Solana Agent Ops** teaches them how to *exist safely* in production. It leverages a progressive loading architecture to save tokens and context while enforcing non-negotiable safety standards.

*   **Rules** are loaded only when specific operational tasks are involved.
*   **SKILL.md** acts as a dynamic router to specialized knowledge modules.
*   **Progressive Loading** ensures you only pay for the context you actually use.

## What This Is

A complete operational framework that turns any agentic setup into a production-grade Solana operator with:

*   **4 Specialized Agents**: Architect, Ops Engineer, Security Auditor, and Solana Guide.
*   **5 Workflow Commands**: Setup Squads, Fund Agent, Deploy TEE, Monitor Agent, and Audit Security.
*   **Modern 2026 Stack**: Built for `@solana/kit` (web3.js 2.x), Squads v4, Helius, and TEEs (Marlin/Phala).
*   **Progressive Skill Loading**: Context-aware routing that minimizes token overhead.
*   **Safety-First Rules**: Always-on enforcement for key management and transaction safety.

## Quick Start

```bash
# Option 1: One-liner installer (Standard)
curl -fsSL https://ops.aikit.codes | bash

# Option 2: Manual setup
git clone https://github.com/your-org/solana-agent-ops-skill.git
cd solana-agent-ops-skill
./install.sh

# Option 3: Selective/Project install
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

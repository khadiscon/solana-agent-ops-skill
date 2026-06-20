# Solana Agent Ops Skill

**Production-grade operational infrastructure for autonomous AI agents on Solana.**

> The Solana Agent Kit taught agents how to **act**. This skill teaches them how to **exist safely** — providing the identity, funding, and security layers required for unattended production execution.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## The Operational Gap

When an agent moves from a local script to a production environment, "actions" are no longer enough. You are suddenly faced with critical infrastructure questions:

1.  **Identity**: How does the agent hold assets without a single-point-of-failure keypair?
2.  **Funding**: How does it stay solvent without being a drainable faucet?
3.  **Confidentiality**: Where do its keys live so a server breach isn't a total loss?
4.  **Observability**: How do you monitor its "health" beyond just logs?
5.  **Safety**: How do you stop it instantly if it goes rogue?

**Solana Agent Ops** is the intentional answer to these questions. It is not a library of actions; it is the **operational framework** that makes those actions safe to run.

---

## Core Pillars

| Pillar | Implementation | The Guarantee |
| :--- | :--- | :--- |
| **Identity** | Squads v4 Smart Accounts | The agent is a *Proposer* on a multisig; the Vault is the durable identity. |
| **Funding** | Bounded Self-Funding | Automated top-ups with hard caps, rate limits, and latching circuit breakers. |
| **Execution** | TEE (Marlin/Phala) | Keys are generated and sealed inside hardware enclaves; never touch disk or env. |
| **Monitoring** | Helius + Kill Switch | Real-time webhook alerts and a tested on-chain authority revocation path. |
| **Payments** | M2M Rails | Secure agent-to-agent payments via escrows and streaming. |

---

## The Stack (2026)

This skill is designed for the modern Solana AI stack:

*   **Runtime**: Node.js 22 LTS / TypeScript 5.6+
*   **Client**: `@solana/kit` (web3.js 2.x)
*   **Identity**: Squads v4 (`@sqds/multisig`)
*   **Actions**: `solana-agent-kit` v2
*   **Infrastructure**: Helius (Data/RPC), Marlin Oyster / Phala (TEE)

---

## Technical Design: Progressive Loading

To remain **token-efficient**, this skill uses a "router" architecture. Instead of loading the entire knowledge base into the agent's context, `SKILL.md` acts as a lightweight dispatcher that pulls in specific modules only when needed.

```text
User Request → SKILL.md (Router) → [Specific Module].md → Execution
```

This ensures the agent stays fast, accurate, and cost-effective even as the operational complexity grows.

---

## Installation

### Quick Start (Standard)
Installs the full skill, agents, and commands to your default Claude configuration (`~/.claude/`).

```bash
git clone https://github.com/your-org/solana-agent-ops-skill.git
cd solana-agent-ops-skill
./install.sh
```

### Selective/Project Install
Use this for custom locations or to install only specific components (e.g., just the security rules).

```bash
./install-custom.sh
```

---

## Guided Workflows

The skill provides specialized commands to handle complex ops tasks safely:

*   **`/setup-squad`**: Initialize a Squads v4 identity with bounded spending limits.
*   **`/fund-agent`**: Configure safety-gated automated funding.
*   **`/deploy-tee`**: Provision a TEE enclave and generate sealed signing keys.
*   **`/monitor-agent`**: Set up Helius-powered observability and alerts.
*   **`/audit-agent`**: Run a pre-mainnet security review against the non-negotiables.

---

## The Non-Negotiables (Safety Culture)

1.  **Simulate Before Send**: Every transaction is dry-run before execution.
2.  **Least Privilege**: The agent is a Proposer with a tight spending limit, never an admin.
3.  **Keys Never Leak**: Private keys belong in TEEs or KMS; they never touch `.env` or logs.
4.  **Human in the Loop**: Large treasury moves require explicit human approval via multisig.
5.  **No Hype**: We state real technical guarantees and their assumptions.

---

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

---

## License
MIT

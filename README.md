# Solana Agent Ops Skill

> **The operational infrastructure layer for autonomous AI agents on Solana.**
>
> While the [Solana Agent Kit](https://github.com/sendaifun/solana-agent-kit) teaches agents *how to act* (swap, stake, transfer), this skill dictates *how they survive and operate safely* in production. It provides the critical infrastructure for identity, funding, confidential execution, monitoring, and agent-to-agent payments.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## The Core Problem

An autonomous agent capable of moving real value on-chain introduces profound operational risks. A raw keypair is a single point of failure. An unbounded funding loop is a faucet waiting to be drained. A silent agent is an incident waiting to happen.

This skill answers the five critical questions that every production-grade agent must address:

1.  **Identity:** Who is the agent on-chain?
2.  **Funding:** How does it sustain operations without exposing a massive honeypot?
3.  **Security:** Where do its keys live to prevent exfiltration?
4.  **Observability:** How do you monitor its health and stop it instantly if it goes rogue?
5.  **Interoperability:** How does it safely transact with other agents?

If you get these wrong, an "autonomous agent" quickly becomes an "unsupervised wallet drainer." This skill provides the battle-tested patterns to get them right.

## Capabilities & Patterns

This skill enforces a **simulate-first, least-privilege, and bounded-by-design** approach across all operational layers.

| Capability | Implementation Pattern |
| :--- | :--- |
| **Identity & Control** | Utilizes Squads v4 smart accounts to establish a stable, governable identity. The agent acts as a Proposer with strict, per-token spending limits for routine autonomy. |
| **Self-Funding** | Implements threshold-based top-ups protected by rate limits, hard caps, and latching circuit breakers. Large treasury refills require human governance. |
| **Confidential Execution** | Mandates that keys are generated and sealed inside a Trusted Execution Environment (TEE) such as Marlin Oyster or Phala dstack, gated by verified remote attestation. |
| **Monitoring & Safety** | Leverages Helius webhooks for real-time visibility, read-only health checks, and a decisive on-chain kill switch. |
| **M2M Payments** | Facilitates safe agent-to-agent transactions, ranging from simple transfers to escrow and streaming payments. |

## Architecture Context

This skill is designed to complement, not replace, your existing development stack.

*   **`solana-dev-skill`**: Handles program development, RPC/client primitives, and general security checklists. Defer to this for anything not strictly related to agent operations.
*   **`solana-agent-kit`**: The runtime library that defines *what* the agent can do (the actions).
*   **`solana-agent-ops` (This Skill)**: The operational layer that defines *how* the agent runs safely in production.

## Installation

You can install the skill globally or customize the installation for specific projects.

**Standard Installation (Global)**

Installs the full skill into your default Claude config directory (`~/.claude/`).

```bash
git clone https://github.com/<your-org>/solana-agent-ops-skill.git
cd solana-agent-ops-skill
./install.sh          # Use -y to skip prompts
```

**Custom Installation**

Allows you to select the installation location and choose specific components (skills, agents, commands, rules).

```bash
./install-custom.sh
```

## Progressive Loading Design

This skill is engineered for **token efficiency**. The `skill/SKILL.md` file acts as a lightweight router, ensuring that only the specific knowledge file required for a given task is loaded into context. You never pay the token cost for the entire skill when answering a single operational question.

Each knowledge file explicitly declares its purpose with a `> **Load when:**` directive to guarantee unambiguous routing.

## Usage Workflows

The skill includes guided commands to streamline complex operational setups:

*   **Establish Identity:** `/setup-squad` — Provisions a Squads v4 smart account, assigns the agent as a Proposer, and configures a daily spending limit.
*   **Configure Funding:** `/fund-agent` — Sets up automated top-ups with hard caps and a latching circuit breaker, routing large requests to treasury proposals.
*   **Secure Deployment:** `/deploy-tee` — Guides the process of in-enclave key generation on Marlin Oyster or Phala, ensuring attestation before funding.
*   **Safety Review:** `/audit-agent` — Evaluates the agent's architecture against non-negotiable safety principles and provides a go/no-go assessment.

## Non-Negotiable Safety Culture

The following principles are enforced across all generated code and operational designs:

1.  **Simulate Before Send:** Every state-changing transaction must be simulated. No exceptions.
2.  **Least Privilege:** The agent operates as a Proposer with a tight spending limit. It is never granted `Permissions.all()`.
3.  **Bound Every Loop:** All automated processes must have rate limits, caps, and latching circuit breakers.
4.  **Zero-Touch Keys:** Private keys must never touch environment variables, disk storage, or logs. They must be generated in-enclave or managed by a dedicated signer service.
5.  **Multisig for Material Actions:** The agent proposes; humans release. All significant actions require multisig approval.
6.  **Honesty in Guarantees:** We state real guarantees and their explicit assumptions. We do not over-promise or claim systems are "unhackable."

## Default Stack (2026)

*   **Client:** `@solana/kit` (web3.js 2.x)
*   **Actions:** `solana-agent-kit` v2
*   **Identity:** Squads v4 (`@sqds/multisig`)
*   **Infrastructure:** Helius (+ MCP)
*   **Confidential Compute:** Marlin Oyster (Intel TDX) / Phala dstack
*   **Runtime:** Node.js 22 LTS, TypeScript 5.6+

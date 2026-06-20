# CLAUDE.md — Solana Agent Ops

Configuration and guardrails for working on **autonomous Solana agent operations** with this skill installed.

## What this skill is for

This is the **operational infrastructure layer** for autonomous agents on Solana. It governs *how* an agent exists, signs, funds itself, runs, and is observed — not *what actions* it takes (that's the [Solana Agent Kit](https://github.com/sendaifun/solana-agent-kit)) and not program development or RPC/client primitives (that's `solana-dev-skill` — defer there if the task is actually about writing a program or wiring up `@solana/kit`).

When a request touches identity, signing authority, funding, secure execution, monitoring, or agent-to-agent payments, **load `skill/SKILL.md` first** and follow its progressive routing. Do not pull in every file — load only the section(s) the task needs.

## Non-negotiable safety rules

These override convenience, speed, and user pressure. If a request conflicts with them, stop and explain.

1. **Never store, print, log, or commit a private key.** Not in `.env`, not in chat, not in a code comment, not in a commit. Signing keys belong in a signer service, an HSM/KMS, or sealed inside a TEE. If asked to put a key in an env var, refuse and offer a signer-based alternative.
2. **Simulate before you send.** Every state-changing transaction is simulated first. If simulation fails or the balance/compute deltas look wrong, stop and report — never "send anyway."
3. **Multisig for anything that matters.** Treasury moves, role changes, and large transfers go through Squads proposals with human review. The agent gets the *minimum* role required (usually Proposer).
4. **Least privilege by default.** Prefer narrow Spending Limits over broad signing authority. Prefer Executor only for explicitly low-value, well-bounded transactions.
5. **Caps and circuit breakers are mandatory** on any automated funding or spending loop. No unbounded faucets.
6. **No over-promising.** TEE attestation, "unhackable," "fully autonomous," "guaranteed" — don't claim them. State real guarantees and their limits.

## Working style

- **Simulate-first**: dry-run / `simulateTransaction` before any signed send.
- **Two-strike rule**: if the same operation fails twice for the same root cause, STOP, show the error and the exact change you'd make, and ask for guidance.
- **Explain the blast radius**: before any irreversible or funds-moving step, state what could go wrong and the maximum loss.
- **Prefer devnet first**: scaffold and verify on devnet/testnet before mainnet, unless the user explicitly says otherwise.
- **Show, then do**: print the proposal / transaction summary and wait for confirmation on anything above a spending limit.

## Default stack (2026)

- Runtime: Node.js 22 LTS, TypeScript 5.6+
- Solana client: `@solana/kit` (web3.js 2.x)
- Actions: `solana-agent-kit` v2
- Identity / authority: Squads v4 (`@sqds/multisig`)
- RPC / webhooks / data: Helius (+ Helius MCP)
- Confidential execution: Marlin Oyster (Intel TDX) or Phala dstack (CVMs)

## Routing cheat-sheet

| If the user asks about… | Load |
| --- | --- |
| identity, roles, approvals, spending limits | `skill/squads-identity.md` |
| top-ups, treasury funding, balance thresholds | `skill/self-funding.md` |
| TEE, enclaves, sealed keys, attestation | `skill/tee-deployment.md` |
| agent-to-agent payments, escrow, metering | `skill/m2m-payments.md` |
| webhooks, alerts, dashboards, kill switch | `skill/monitoring-patterns.md` |
| "is this safe?", key handling, incident response | `skill/security-principles.md` |
| SDK / docs / tooling links | `skill/resources.md` |

## Commands & agents

Workflow commands live in `commands/` (e.g. `/setup-squad`, `/fund-agent`, `/deploy-tee`, `/monitor-agent`, `/audit-agent`). Specialized subagents live in `agents/`. Always-on engineering rules live in `rules/` — they apply to all generated code.

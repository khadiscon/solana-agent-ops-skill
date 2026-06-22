---
name: solana-agent-ops
description: >-
  Operational infrastructure for running autonomous AI agents in production on
  Solana: on-chain identity and control (Squads v4), self-funding with safety
  rails, confidential execution in TEEs (Marlin Oyster, Phala), real-time
  monitoring (Helius), and machine-to-machine payments. Load when building,
  funding, securing, deploying, or monitoring an autonomous Solana agent — the
  ops layer that complements the Solana Agent Kit's actions. Does NOT cover
  program development, RPC/client primitives, or general security checklists
  — defer those to solana-dev-skill.
---

# Solana Agent Ops

> **Layer:** operational/ops. **Defers to:** `solana-dev-skill` for program development, RPC/client primitives, and general security checklists (this skill doesn't duplicate them — see "Out of scope" below). **Complements:** the [`solana-agent-kit`](https://github.com/sendaifun/solana-agent-kit) library — not a skill, a runtime dependency the agent calls into for actions.

The **Solana Agent Kit gives an agent actions** (swap, stake, transfer, deploy). This skill gives it the **operational layer that makes those actions safe to run unattended**: a stable identity, bounded authority, a way to stay funded, a place to run where its keys can't be stolen, eyes on its behavior, and a way to pay other agents.

> **Read this router first, then load only the file(s) the task needs.** Each knowledge file is self-contained and opens with a `> **Load when:**` line. Don't load everything — progressive loading is the point.

## Mental model

Five questions every production agent must answer. This skill answers each with one file:

```
WHO is the agent on-chain?      → squads-identity.md   (smart account = identity)
HOW does it stay funded?        → self-funding.md      (bounded auto top-ups)
WHERE do its keys live?         → tee-deployment.md    (sealed in a TEE)
HOW do you know it's healthy?   → monitoring-patterns.md(webhooks + kill switch)
HOW does it pay other agents?   → m2m-payments.md      (escrow → streaming)
```

Two files apply across all of the above:

```
What must NEVER be violated?    → security-principles.md (the non-negotiables)
Where are the authoritative docs?→ resources.md          (2026 stack links)
```

One principle ties it together: **the smart account is the identity; the keypair is a replaceable, sealed signer.** Internalize that and the rest follows.

## Routing table

| If the task is about… | Load |
| --- | --- |
| Identity, signer roles, approvals, spending limits | `squads-identity.md` |
| Keeping the agent funded, top-ups, treasury refills | `self-funding.md` |
| Where keys live, confidential execution, attestation | `tee-deployment.md` |
| Watching the agent, alerts, kill switch | `monitoring-patterns.md` |
| Agent-to-agent payments, escrow, streaming | `m2m-payments.md` |
| “Is this safe?”, key handling, threat model, incident response | `security-principles.md` |
| SDKs, RPC, docs, tooling links | `resources.md` |

## Out of scope — defer to `solana-dev-skill`

This skill governs *operations* around an agent that already exists; it does not teach program development or client setup. If the task is actually one of these, load `solana-dev-skill` instead (or first):

| If the task is about… | Defer to (`solana-dev-skill`) |
| --- | --- |
| Writing/testing an Anchor or Pinocchio program | `programs-anchor.md` / `programs-pinocchio.md` |
| `@solana/kit` client setup, or bridging it with classic `web3.js` (several SDKs used here, e.g. `@sqds/multisig`, still expect classic `web3.js` types) | `kit-web3-interop.md` |
| General program/client security checklist (not agent-ops-specific) | `security.md` |
| IDL generation, client codegen | `idl-codegen.md` |
| Calling agent actions (swap/stake/transfer/mint/deploy) | the `solana-agent-kit` library directly — it's a runtime dependency, not a skill; see `resources.md` |

If `solana-dev-skill` isn't installed, say so plainly rather than improvising program-development guidance this skill isn't scoped to give.

## Common task → file combos

- **Stand up a new agent (end to end):** `tee-deployment.md` (keygen) → `squads-identity.md` (identity + roles) → `self-funding.md` (funding) → `monitoring-patterns.md` (observability). Cross-check against `security-principles.md`.
- **“Make my agent safe for mainnet”:** `security-principles.md` + the files for each layer it touches.
- **“Let my agent pay another agent”:** `m2m-payments.md` (+ `squads-identity.md` for the spending-limit budget).
- **“My agent keeps running out of SOL”:** `self-funding.md`.

## Default stack (2026)

| Concern | Default |
| --- | --- |
| Client | `@solana/kit` (web3.js 2.x) |
| Actions | `solana-agent-kit` v2 |
| Identity & control | Squads v4 (`@sqds/multisig`) |
| RPC / data / webhooks | Helius (+ Helius MCP) |
| Confidential execution | Marlin Oyster (Intel TDX) · Phala dstack (CVMs) |
| Runtime | Node.js 22 LTS, TypeScript 5.6+ |

## Operating principles (always on)

1. **Simulate before send.** Every state-changing tx. No exceptions.
2. **Least privilege.** Agent = Proposer + a tight spending limit, never `all()`.
3. **Bound every loop.** Rate limit + caps + a latching circuit breaker.
4. **Keys never touch env/disk/logs.** Generate in-enclave or use a signer service.
5. **Multisig for anything that matters.** Agent proposes; humans release.
6. **Be honest.** State real guarantees and their assumptions — never “unhackable.”

These are enforced in `rules/` and detailed in `security-principles.md`.

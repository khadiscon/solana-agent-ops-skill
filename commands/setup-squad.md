---
name: setup-squad
description: Create a Squads v4 smart account as the agent's on-chain identity, with least-privilege roles and a right-sized spending limit.
---

# /setup-squad

Stand up the agent's durable on-chain identity as a Squads v4 smart account. The vault PDA becomes the agent's address; the agent signer is a Proposer member; humans are Voters; a tight Spending Limit enables routine autonomy.

## Load first

- `skill/squads-identity.md` (primary)
- `skill/security-principles.md` (key handling, least privilege)

## Inputs to gather

- Operator pubkeys (≥ 2 humans) and desired threshold (default 2).
- The agent signer pubkey **and where its key lives** (ideally a TEE — see `/deploy-tee`). Never accept a raw private key.
- Network (default: staging/non-production first).
- Spending-limit budget: token(s), amount, window (day/week/month), and destination allowlist.
- Whether the agent should also be an Executor (auto-execute approved proposals).

## Procedure

1. Confirm the agent signer is **Proposer only** (optionally + Executor) — never `Permissions.all()`.
2. Create the multisig (`multisigCreateV2`) with operators as full members and the agent as Proposer; threshold ≥ 2.
3. Derive and record the **vault PDA (index 0)** — this is the agent's identity. Fund it only in the selected staging environment until the mainnet review is complete.
4. Add a **Spending Limit** (`multisigAddSpendingLimit`) per the budget, with `destinations` allowlisted in production.
5. Keep preflight/simulation enabled on every config transaction.
6. Output: multisig PDA, vault PDA, member/role table, spending-limit summary, and a signer-rotation note.

## Guard rails

- Refuse any flow that requires pasting a private key.
- Threshold must be ≥ 2 for value-moving transactions.
- Spending limit must be bounded and, in production, destination-restricted.
- Stop and confirm before running against mainnet.

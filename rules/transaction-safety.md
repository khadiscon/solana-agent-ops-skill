---
name: transaction-safety
alwaysApply: true
description: Mandatory safety constraints for every transaction an autonomous agent builds, signs, or sends.
---

# Rule: Transaction Safety

Applies to every state-changing transaction, no exceptions.

## Simulate before send

- Always `simulateTransaction` / keep preflight on before signing or sending.
- Inspect the error **and** the balance/compute deltas. Abort on failure or anything unexpected.
- Never "send anyway" after a failed simulation.

## Least privilege

- The agent's Squads role is **Proposer** (optionally + Executor), never `Permissions.all()`.
- Routine spend flows under a **tight Spending Limit** (per token + window), with destinations allowlisted in production.
- Credentials are scoped; monitoring credentials are read-only.

## Multisig for anything that matters

- Treasury moves, role/config changes, and large transfers go through Squads proposals with human review.
- The agent has **propose-only** authority over the treasury — it never releases treasury funds itself.

## Bound every loop

- Funding/spending automation must have a rate limit, a per-action cap, a rolling-window cap, and a **latching circuit breaker** that only a human resets.

## Idempotency

- On an ambiguous send result, check the chain before retrying — never double-spend or double-fund.
- Record signatures; reconcile against intended actions.

## Devnet first

- Validate flows on devnet/testnet before mainnet. Mainnet is a deliberate, reviewed step — stop and confirm.

## Two-strike rule

- If the same operation fails twice for the same root cause, STOP, show the error and the exact change you'd make, and ask for guidance instead of looping.

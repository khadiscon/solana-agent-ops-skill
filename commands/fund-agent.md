---
name: fund-agent
description: Configure threshold-based self-funding for the agent with rate limits, caps, a latching circuit breaker, and treasury-gated large top-ups.
---

# /fund-agent

Keep the agent funded without turning it into a faucet. Small refills happen automatically under hard caps; large refills become treasury proposals a human approves.

## Load first

- `skill/self-funding.md` (primary)
- `skill/monitoring-patterns.md` (balance webhooks, trip alerts)
- `skill/security-principles.md` (bounded loops)

## Inputs to gather

- Agent vault address (from `/setup-squad`).
- Refill source: a small hot refill wallet **or** a Squads Spending Limit (preferred).
- Tier-1 params: `thresholdSol` (e.g. 0.05), `targetSol` (e.g. 0.2), `maxPerTopUpSol`, `maxPerWindowSol`, `windowMs`, `minIntervalMs`, `maxTopUpsPerWindow`.
- Treasury multisig PDA + vault (for Tier-2), and the boundary amount where treasury approval kicks in.
- Helius RPC URL (read scope).

## Procedure

1. Implement the Tier-1 `AgentFunder` with **all** guards: rate limit, per-top-up cap, rolling-window cap, latching circuit breaker.
2. Simulate every top-up transfer before sending; skip (don't throw) on guard violations; log `{action, reason, amount, balanceBefore}`.
3. Wire Tier-2: the agent **proposes** a treasury→agent transfer (`vaultTransactionCreate` + `proposalCreate`); operators vote + execute. The agent never releases treasury funds itself.
4. Add alerts on every top-up and every breaker trip (route to a human channel).
5. Document the manual breaker-reset procedure (requires investigation).
6. Keep the refill wallet small enough to bound worst-case loss.

## Guard rails

- No unbounded funding loop — caps + breaker are mandatory.
- Agent has propose-only authority over the treasury.
- Breaker latches; only a human resets it.
- Every send simulated and idempotent.

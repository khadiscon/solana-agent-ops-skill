---
name: monitor-agent
description: Stand up real-time monitoring for the agent with Helius webhooks, a read-only health checker, anomaly alerts, and a tested kill switch.
---

# /monitor-agent

Give yourself eyes on the agent and a decisive way to stop it.

## Load first

- `skill/monitoring-patterns.md` (primary)
- `skill/squads-identity.md` (kill switch = revoke authority)

## Inputs to gather

- Agent vault address.
- Helius API key (read scope) and a public HTTPS webhook endpoint + shared secret.
- Alert channel (Slack / PagerDuty / Telegram).
- Thresholds: low-balance floor, large-tx value, counterparty allowlist, failure tolerance.

## Procedure

1. Register a Helius **enhanced webhook** for the vault; require and verify the shared secret on receipt.
2. Implement a **read-only** receiver that classifies events and alerts — **no keys, no send paths**; dedupe on signature.
3. Add a **read-only health-check** loop (balance floor, recent failures); fail loud, never silent; bounded interval.
4. Optionally wire **Helius MCP** with read-only query tools for investigation.
5. Configure the minimum-viable signal set (balance, volume, value, failures, new counterparties, limit usage, breaker trips, attestation drift).
6. Document and **test the kill switch**: Layer-1 = revoke the agent's spending limit + remove the member in Squads.

## Guard rails

- Monitoring holds no keys and cannot move funds.
- Webhook secret verified on every request; handlers idempotent.
- Kill switch's authoritative layer is on-chain authority revocation, and it has been rehearsed.

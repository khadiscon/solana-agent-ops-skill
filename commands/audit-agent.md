---
name: audit-agent
description: Run the pre-mainnet security audit of an autonomous Solana agent against the non-negotiables and threat model, producing a go/no-go recommendation.
---

# /audit-agent

Adversarially review the agent's design and code before it touches mainnet. Block on any open BLOCKER.

## Load first

- `skill/security-principles.md` (primary)
- Whichever files the design touches (`squads-identity.md`, `self-funding.md`, `tee-deployment.md`, `m2m-payments.md`, `monitoring-patterns.md`)

## Procedure

1. **Check the seven non-negotiables**:
   - No key in env/file/log/commit/chat.
   - Simulate before send, everywhere.
   - Least privilege (Proposer, not `all()`; tight spending limits).
   - Multisig for anything that matters.
   - Bounded loops (rate limit + caps + latching breaker).
   - Observation separated from action (read-only monitoring).
   - No over-promising; assumptions documented.
2. **Walk the threat model** (key exfiltration, compromised signer, runaway loop, malicious counterparty, prompt injection, treasury drain, supply chain, silent failure, over-trusted TEE) — confirm a mitigation for each.
3. **Single-failure test**: "If exactly one control fails, what's the worst case?" Flag any total-loss path.
4. **Verify** the kill switch + incident runbook exist and are testable.
5. **Report** findings as a table: severity (BLOCKER / HIGH / MEDIUM / NOTE) · issue · location · fix. End with a go/no-go and the marked pre-production checklist.

## Guard rails

- A key in env/file/log/commit is an automatic BLOCKER.
- Unsimulated sends, unbounded loops, and agent-controlled treasury are BLOCKERs.
- No mainnet go-ahead while any BLOCKER is open.

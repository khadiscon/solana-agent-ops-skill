---
name: solana-ops
alwaysApply: true
description: Stack conventions, dependency hygiene, logging, and honesty standards for Solana agent ops code.
---

# Rule: Solana Ops Conventions

## Stack (2026 default)

- Runtime: Node.js 22 LTS, TypeScript 5.6+.
- Solana client: `@solana/kit` (web3.js 2.x).
- Actions: `solana-agent-kit` v2. Identity/authority: Squads v4 (`@sqds/multisig`). RPC/data/webhooks: Helius.
- Confidential execution: Marlin Oyster (Intel TDX) or Phala dstack (CVMs).
- Prefer the modern client and current SDK patterns; verify versions against upstream docs (`skill/resources.md`) — APIs move.

## Code quality

- TypeScript with explicit types; avoid `any` on public boundaries.
- Pure functions where possible; isolate and log side effects (sends).
- Keep the **signer process minimal** — every dependency in it is attack surface.

## Dependency hygiene

- Pin exact versions; commit a lockfile.
- Minimize the dependency surface, especially around custody/signing.
- Prefer **audited** programs for escrow/streaming; do not hand-roll custody for real value.

## Logging

- Log decisions, not secrets: `{action, reason, amount, signature, balanceBefore}`.
- Never log keys, seeds, or full payloads containing secrets.
- Monitoring/health checks fail **loud**, never silent.

## Honesty

- No over-promising: don't claim "unhackable," "fully trustless," "zero-risk," or "guaranteed."
- State the real guarantee **and its assumptions** (e.g. "keys are protected *given* the TEE hardware and a verified attestation").
- No shady code: no obfuscation, no hidden transfers, no backdoors.

---
name: deploy-tee
description: Deploy the agent to a confidential runtime (Marlin Oyster or Phala dstack) with in-enclave key generation and attestation-gated signer registration.
---

# /deploy-tee

Run the agent where its signing key can never be exfiltrated, and gate trust on a verified remote attestation.

## Load first

- `skill/tee-deployment.md` (primary)
- `skill/squads-identity.md` (signer registration gate)
- `skill/security-principles.md` (key custody)

## Inputs to gather

- Deployment goal: a minimal **sealed signer** (→ Marlin Oyster) or a **full agent runtime / private inference** (→ Phala dstack)?
- Agent framework (e.g. Eliza) if applicable.
- Expected measurement source (reproducible build) and where it will be pinned.
- Squads multisig PDA to register the verified signer into.
- Runtime secrets to provision (RPC URL, config) — never committed.

## Procedure

1. **Choose the platform** and justify it (Oyster = sealed signer; Phala = full agent / private inference / Eliza).
2. Build the enclave image (Oyster) or container (Phala) with **in-enclave key generation** and **export disabled**.
3. Deploy to the confidential runtime; provision secrets at runtime.
4. Fetch the attestation quote/report; **verify against the pinned measurement** + freshness.
5. Only on pass: register the enclave public key as a Squads **Proposer** member; then allow funding.
6. Pin the measurement in config; add a drift alert; document the rotation runbook (new code → new measurement → re-attest → rotate member).

## Guard rails

- Key is generated in-enclave and non-exportable.
- No signer is trusted, funded, or added to the multisig without a verified attestation.
- Secrets provisioned at runtime, never committed.
- No "unhackable" claims — document guarantees and assumptions.

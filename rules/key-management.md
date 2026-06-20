---
name: key-management
alwaysApply: true
description: How signing keys are created, stored, used, and rotated for autonomous Solana agents.
---

# Rule: Key Management

The cardinal rule of agent ops. A leaked key is total, irreversible loss. These constraints are absolute.

## Never

- **Never** put a private key, seed phrase, or keypair JSON in an environment variable, `.env` file, source file, Docker image, log line, commit, or chat/output. If asked to, **refuse** and offer a signer-based alternative.
- **Never** export a key from a TEE/KMS "for backup." If it can be exported, it can be stolen.
- **Never** reuse one key across environments (dev/stage/prod) or across agents.

## Always

- **Generate keys inside a TEE** when possible (in-enclave, non-exportable) — see `skill/tee-deployment.md`. Otherwise use a **signer service / KMS / HSM** that signs on request and never returns the key.
- **Make the on-chain identity a Squads vault**, not a keypair, so a compromised signer can be rotated without losing the identity — see `skill/squads-identity.md`.
- **Provision secrets at runtime**, never bake them into images or commit them.
- **Maintain a rotation runbook**: remove the compromised member, add a fresh in-enclave signer, re-establish spending limits. The vault address survives.
- **Git-ignore** `*.json` keypairs, `*.pem`, `*.key`, `id.json`, and secret-bearing `.env` files.

## On compromise

1. Hit the kill switch (revoke the agent's spending limit + remove the member in Squads).
2. Rotate to a fresh in-enclave signer.
3. Sweep at-risk funds to a safe vault.
4. Investigate which layer failed; add the missing one.

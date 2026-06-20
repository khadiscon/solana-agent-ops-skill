# Security Principles

> **Load when:** any task moves real funds, handles keys, or the user asks "is this safe?". These are the non-negotiables that override convenience, speed, and pressure. When a request conflicts with one, stop and explain.

Autonomous agents are an attractive attack surface: they hold keys, move funds, run unattended, and act fast. The difference between a production agent and a liability is discipline. This file is the security backbone the rest of the skill assumes.

## The seven non-negotiables

### 1. Never store a private key in an environment variable, file, log, or commit

This is the cardinal rule. A key in `.env`, in a Docker image, in a log line, in chat output, or in git history is a key that will eventually leak.

**Instead:**

- **Best:** generate the key **inside a TEE**; it never exists in plaintext outside the enclave (see `tee-deployment.md`).
- **Good:** a dedicated **signer service / KMS / HSM** that signs on request and never returns the key.
- **Acceptable for dev only:** an encrypted keystore unlocked at runtime, on a machine you control, never committed.
- **Never:** `PRIVATE_KEY=...` in `.env`, hardcoded arrays, pasted into chat.

If asked to put a key in an env var, **refuse** and offer a signer-based alternative. No exceptions “just for testing” on anything that touches mainnet or real value.

### 2. Simulate before you send — always

Every state-changing transaction is simulated first (`simulateTransaction` / preflight). Inspect the result *and* the balance/compute deltas. Abort on failure or anything surprising.

```ts
const sim = await connection.simulateTransaction(tx);
if (sim.value.err) {
  throw new Error(`Refusing to send — simulation failed: ${JSON.stringify(sim.value.err)}`);
}
// Also sanity-check: did this move the amount we expected, and only that?
```

Never “send anyway” after a failed simulation. A failed sim is the cheapest possible warning you'll get.

### 3. Least privilege everywhere

Give the agent the **smallest authority** that lets it do its job:

- **Role:** Proposer, not `Permissions.all()` (see `squads-identity.md`).
- **Spend:** a tight per-token, per-window Spending Limit, with allowlisted destinations.
- **Credentials:** scoped, read-only API keys for monitoring; separate keys per concern.
- **Blast radius:** the maximum an agent can lose in its worst hour should be a number you've consciously chosen.

### 4. Multisig for anything that matters

Treasury moves, role/config changes, and large transfers go through **Squads proposals with human review**. The agent proposes; humans (or a governance set) approve. Routine, bounded actions use Spending Limits so you're not approving trivia by hand — but the things that can hurt you require a human.

### 5. Bound every automated loop

Any funding or spending automation must have: a **rate limit**, a **per-action cap**, a **rolling-window cap**, and a **circuit breaker** that latches off until a human investigates (see `self-funding.md`). An unbounded loop is a drain waiting to happen.

### 6. Separate observation from action

Monitoring code is **read-only** and holds **no keys** (see `monitoring-patterns.md`). The thing that watches the agent must not be able to move its funds. Action paths (kill switch, fund release) are deliberately gated and separate.

### 7. State real guarantees — never over-promise

Don't claim “unhackable,” “fully trustless,” “zero-risk,” or “guaranteed.” A TEE protects keys *given* the hardware and attestation hold. A multisig protects *given* the threshold of signers isn't compromised. Always state the guarantee **and its assumptions**. Honest limits build trust; hype destroys it.

## Defense in depth (how the layers stack)

No single control is sufficient. They compose so that any one failure isn't catastrophic:

```
Layer 1  Key custody     → key sealed in TEE / KMS (can't be exfiltrated)
Layer 2  Authority       → Squads role = Proposer (can't unilaterally move funds)
Layer 3  Spend bounds    → Spending Limit caps per-token, per-window
Layer 4  Pre-flight      → simulate every tx (catch bad/unexpected actions)
Layer 5  Funding bounds  → caps + circuit breaker (can't drain via top-ups)
Layer 6  Observability   → webhooks + alerts (you see anomalies fast)
Layer 7  Kill switch     → revoke authority on-chain (decisive stop)
```

Ask of any design: *"If exactly one of these fails, what's the worst outcome?"* If the answer is "total loss," add a layer.

## Threat model for autonomous agents

| Threat | Primary mitigation |
| --- | --- |
| Key exfiltration (host, backup, dependency) | TEE-sealed or KMS keys; never in env/disk |
| Compromised agent signer | Squads role = Proposer; spending limit; rotate member |
| Runaway / looping behavior | Rate limits, caps, circuit breakers |
| Malicious counterparty (M2M) | Escrow, allowlists, simulate, bounded spend |
| Prompt injection / poisoned input steering actions | Spending limits + simulation + human gate on big moves |
| Treasury drain | Agent is propose-only; treasury threshold + review |
| Supply-chain (malicious npm dep) | Pin versions, lockfiles, minimal deps, audit |
| Silent failure / blind operation | Loud monitoring, fail-safe defaults, alerting |
| Over-trusting a TEE/attestation | Verify against pinned measurement; document assumptions |

### Prompt injection deserves special care

An agent that reads untrusted input (web, messages, other agents) can be *steered*. The defense is **not** “make the prompt perfect” — it's that **even a fully hijacked agent is bounded**: its spending limit, its propose-only role, simulation, and the human gate on large moves cap the damage. Design so a compromised reasoning layer still can't drain the vault.

## Secure development practices

- **Pin dependencies.** Exact versions + lockfile. Minimize the dependency surface; every transitive dep can sign-jack if it runs in the signer's process.
- **Keep the signer process minimal.** The fewer things running where the key lives, the smaller the attack surface. The TEE pattern enforces this.
- **Devnet first.** Validate flows on devnet/testnet before mainnet. Treat the mainnet deploy as a deliberate, reviewed step.
- **Idempotency.** On ambiguous send results, check the chain before retrying — never double-spend.
- **Log decisions, never secrets.** `{action, reason, amount, signature}` — yes. Keys, seeds, full payloads with secrets — never.
- **Reproducible deploys.** Especially for TEEs, where the measurement *is* your identity. A changed build = a changed measurement = re-attest + rotate.

## Incident response runbook

When something looks wrong, act in this order:

```
1. CONTAIN (seconds)
   - Hit the kill switch: revoke the agent's spending limit + remove the
     member in Squads. Authority gone = bleeding stopped.
2. ASSESS
   - What moved, where, how much, since when? Use Helius (webhooks/MCP) to
     reconstruct the timeline.
3. ROTATE
   - Generate a fresh signer (in-TEE). Remove the compromised member, add
     the new one. Identity (vault) is preserved.
4. RECOVER
   - Sweep at-risk funds to a safe vault. Re-establish spending limits for
     the new signer.
5. LEARN
   - Which layer failed? Add the missing one. Update this runbook.
```

Rehearse this **before** you need it. An incident is the wrong time to discover your kill switch doesn't work.

## Pre-production security checklist

- [ ] No private key in any env var, file, log, commit, or chat — verified
- [ ] Signing key is TEE-sealed or in a KMS/HSM; never exportable
- [ ] Agent's Squads role is Proposer (optionally + Executor), never `all()`
- [ ] Tight Spending Limit per token + window, destinations allowlisted
- [ ] Every state-changing tx is simulated before send
- [ ] Funding loops have rate limit + caps + latching circuit breaker
- [ ] Monitoring is read-only with no keys; alerts reach a human
- [ ] Kill switch (on-chain authority revoke) tested and rehearsed
- [ ] Incident-response runbook written and rehearsed
- [ ] Dependencies pinned; signer process minimized
- [ ] Validated on devnet before mainnet
- [ ] No "unhackable"/"trustless" claims; assumptions documented

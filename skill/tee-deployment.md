# TEE Deployment Patterns

> **Load when:** deciding where the agent's signing key lives, deploying to a confidential runtime, or implementing remote attestation. This is how a key "never exists in plaintext outside the enclave" becomes real.

The hardest problem in agent ops is key custody: an autonomous agent must sign, but a key on a normal host can be stolen by anyone who compromises that host. A **Trusted Execution Environment (TEE)** runs code in a hardware-isolated enclave where the key is **generated inside and never leaves** — and **remote attestation** lets you cryptographically verify *which* code is running before you trust it with funds.

```
Key on a VM            →  host compromise = key gone
Key in a TEE enclave   →  key born inside, non-exportable; only
                          signatures + a verifiable attestation leave
```

## The two patterns

| | **Marlin Oyster** | **Phala Network** |
| --- | --- | --- |
| Shape | Sealed **signer/service** enclave | Full **agent runtime** in a CVM |
| Tech | Intel TDX, reproducible enclave image | dstack + Confidential VMs (containers) |
| Best for | Tightest key isolation; minimal attack surface | Shipping a whole agent; **private inference**; **Eliza** apps |
| Attestation | RA over the enclave image measurement | RA report over the CVM |
| Mental model | "HSM you can verify remotely" | "Confidential container host" |

Both give you: in-enclave key generation, non-exportable keys, and remote attestation. Choose by **scope** — seal just the signer (Oyster) or run the whole agent confidentially (Phala).

### When to choose which

- **Marlin Oyster** — you want the smallest trusted surface: a minimal signer that holds the key and exposes only `sign()`. Everything else runs normally. Easiest to reason about and audit.
- **Phala dstack** — you want the *entire* agent (reasoning, tools, model calls) inside the TEE, container-native deploys, or **private inference** so prompts/outputs stay confidential. Strong fit for **Eliza**-based agents.

> Real-world TEE agents (e.g. **KobotoAI**, **Magic Newton**, **Spore.fun**-style autonomous agents) use this shape: keys sealed in-enclave, identity on-chain, actions gated by attestation. Treat these as orientation, not endorsement — verify each project's current design yourself.

## Pattern A — Marlin Oyster sealed signer

The enclave generates the keypair on first boot, persists it to the **sealed filesystem** (data encrypted to the enclave's PCR identity — unreadable outside this specific enclave image), and exposes only signing.

```ts
// Runs INSIDE the enclave. The secret key never appears in any return value,
// log, or external call — only the public key and signatures leave.
import { Keypair } from "@solana/web3.js";
import nacl from "tweetnacl";
import * as fs from "fs";
import * as path from "path";

// In Marlin Oyster, the sealed filesystem is mounted at /run/secrets (or
// equivalent — verify the current mount path in Marlin's docs before deploying).
// Data written here is encrypted to the enclave's PCR measurements and is
// unreadable outside this specific enclave image.
const SEALED_KEY_PATH = process.env.SEALED_KEY_PATH ?? "/run/secrets/agent.key";

class SealedSigner {
  private keypair: Keypair;

  constructor() {
    this.keypair = this.loadOrCreateSealed();
  }

  getPublicKey(): string {
    return this.keypair.publicKey.toBase58();
  }

  sign(messageB64: string): string {
    const sig = nacl.sign.detached(
      Buffer.from(messageB64, "base64"),
      this.keypair.secretKey
    );
    return Buffer.from(sig).toString("base64");
  }

  private loadOrCreateSealed(): Keypair {
    const dir = path.dirname(SEALED_KEY_PATH);

    if (fs.existsSync(SEALED_KEY_PATH)) {
      // Reload: the sealed FS decrypts transparently for this enclave identity.
      // If the read fails, the enclave identity has changed (new build). Treat as
      // a new boot — do NOT log or expose the failed bytes.
      try {
        const raw = fs.readFileSync(SEALED_KEY_PATH);
        if (raw.length !== 64) throw new Error(`unexpected key length: ${raw.length}`);
        return Keypair.fromSecretKey(raw);
      } catch (e) {
        // Log the failure, never the key material.
        console.error("[SealedSigner] sealed key unreadable, generating fresh. Cause:", (e as Error).message);
        // Fall through to fresh generation below.
      }
    }

    // First boot (or after a PCR change): generate a fresh keypair, persist sealed.
    const kp = Keypair.generate();
    fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
    fs.writeFileSync(SEALED_KEY_PATH, Buffer.from(kp.secretKey), {
      mode: 0o600, // owner-read only
      flag: "wx",  // fail if file already exists (race-safe)
    });
    // Log the new public key — NEVER the secret key.
    console.info("[SealedSigner] fresh keypair sealed. Public key:", kp.publicKey.toBase58());
    return kp;
  }
}
```

> **What "sealed" means here:** The enclave's PCR measurements (a fingerprint of the exact code running) are used as an encryption key by the Oyster platform. Only the same enclave image can decrypt. A different build, a compromised host, or a malicious operator cannot read the sealed key. Verify this claim against Marlin's current attestation documentation before trusting it with real funds.

## Attestation gate (the part that matters)

A TEE is only as trustworthy as your **verification** of its attestation. Never trust a signer because it *claims* to run in a TEE — verify the quote against a **pinned measurement** and a fresh nonce before funding it or adding it to the multisig.

```ts
// Runs on the CLIENT/operator side, before trusting the enclave.
import { PublicKey } from "@solana/web3.js";

async function adoptSealedAgent(p: {
  endpoint: string; expectedMeasurement: string; // pinned from a reproducible build
}): Promise<{ trustedPubkey: PublicKey }> {
  const nonce = crypto.randomUUID();
  const att = await fetch(`${p.endpoint}/attestation?nonce=${nonce}`).then((r) => r.json());

  if (!verifyAttestationSignature(att))          throw new Error("attestation signature invalid");
  if (att.measurement !== p.expectedMeasurement)  throw new Error("measurement mismatch — unknown/unexpected code");
  if (att.nonce !== nonce)                        throw new Error("stale attestation (replay)");

  // Only now is the enclave's pubkey safe to register as a Squads Proposer + fund.
  return { trustedPubkey: new PublicKey(att.publicKey) };
}
declare function verifyAttestationSignature(att: any): boolean; // verify cert chain to vendor root (Intel TDX, etc.)
```

**Gate sequence:** deploy enclave → fetch attestation → verify (signature + measurement + nonce) → register pubkey as Squads Proposer (`squads-identity.md`) → enable funding (`self-funding.md`). Skip the gate and you've trusted an unknown binary with a vault.

## Pattern B — Phala dstack (full agent CVM)

Ship the agent as a container to a Confidential VM. The CVM provides the attestation report; **private inference** keeps model I/O confidential; the same attestation gate applies before the agent's key is trusted on-chain.

```yaml
# dstack manifest — the whole agent runs confidentially inside a CVM.
# Replace the image field with your actual container registry path and pinned digest.
# Pin by digest (not tag) to make the enclave measurement reproducible.
# Get the digest after building: docker inspect --format='{{index .RepoDigests 0}}' your-image
name: solana-agent
image: ghcr.io/example-org/solana-agent@sha256:<pinned-digest>
resources: { vcpu: 2, memory: 4Gi }
secrets: [HELIUS_RPC_URL]      # injected at runtime, never baked into the image
attestation: { enabled: true } # exposes a verifiable RA report
```

Eliza-based agents fit naturally here: the framework runs in-CVM, the wallet plugin uses an in-enclave key, and inference can stay private.

## Key management rules (non-negotiable)

- **Generated in-enclave, never imported, never exported.** No "export for backup" — if it can leave, it can be stolen. Survivability comes from Squads rotation, not key backups.
- **Pin the measurement** from a reproducible build; alert + rotate on any drift.
- **Secrets at runtime only** (RPC URLs, config) — never baked into images or committed.
- **Rotation:** new code → new measurement → re-attest → swap the Squads member. Identity (vault) persists.

## Honest guarantees

A TEE protects the key **given** the hardware (e.g. Intel TDX), a correct attestation verification, and a sound enclave image. It is **not** "unhackable." State the guarantee with its assumptions; never market it as absolute.

## Checklist

- [ ] Platform chosen deliberately: Oyster (sealed signer) vs Phala (full agent / private inference)
- [ ] Key generated **inside** the enclave; export disabled
- [ ] Attestation verified (signature + pinned measurement + fresh nonce) before trust
- [ ] Verified pubkey registered as Squads Proposer; funding enabled only after
- [ ] Measurement pinned; drift alerts wired
- [ ] Secrets injected at runtime, never committed
- [ ] Rotation runbook documented (re-attest → swap member)
- [ ] Guarantees stated with assumptions — no "unhackable" claims

**Next:** register the verified signer → `squads-identity.md` · fund it → `self-funding.md` · watch it → `monitoring-patterns.md`

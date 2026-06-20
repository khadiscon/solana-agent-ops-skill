# Self-Funding & Automated Top-ups

> **Load when:** the task involves keeping the agent funded — balance thresholds, automated top-ups, treasury approval for larger amounts, or the safety rails around funding.

An agent that runs out of SOL stalls mid-task. An agent with an unbounded funding loop is a faucet waiting to be drained. The goal: **small refills happen automatically under hard caps; large refills become treasury proposals a human approves.**

## Two-tier model

```
            Agent vault
                │  balance < threshold (e.g. 0.05 SOL)?
        ┌───────┴───────┐
        ▼                ▼
  Tier 1: micro     Tier 2: treasury
  auto refill       agent PROPOSES, humans
  via Spending      VOTE + release
  Limit / hot       (Squads threshold)
  wallet
  rate-limited,     agent never controls
  capped, broken    the treasury directly
```

- **Tier 1 (automatic):** a small refill source tops the agent up by a fixed amount when it dips below threshold. Strictly bounded.
- **Tier 2 (governed):** larger refills are *proposed* by the agent against the treasury multisig and *released* by humans.

> ⚠️ The agent's authority over the treasury is **propose-only** (see `squads-identity.md`). Never let it pull arbitrary amounts.

## Tier 1: threshold top-up with safety rails

Every guard is mandatory: **rate limit**, **per-top-up cap**, **rolling-window cap**, **latching circuit breaker**, and **simulate-before-send**.

```ts
import { Connection, PublicKey, SystemProgram, Transaction, LAMPORTS_PER_SOL } from "@solana/web3.js";

interface TopUpConfig {
  thresholdSol: number;       // refill below this (e.g. 0.05)
  targetSol: number;          // refill up to this (e.g. 0.2)
  maxPerTopUpSol: number;     // cap per refill
  maxPerWindowSol: number;    // rolling cap across window
  windowMs: number;           // e.g. 1h
  minIntervalMs: number;      // rate limit, e.g. 10m
  maxTopUpsPerWindow: number; // circuit-breaker count
}
interface TopUpState { history: Array<{ ts: number; amountSol: number }>; tripped: boolean; }

export class AgentFunder {
  constructor(
    private connection: Connection,
    private refillSigner: { publicKey: PublicKey; sign: (tx: Transaction) => Promise<Transaction> },
    private agentVault: PublicKey,
    private cfg: TopUpConfig,
    private state: TopUpState = { history: [], tripped: false },
  ) {}

  private recent() {
    const cutoff = Date.now() - this.cfg.windowMs;
    this.state.history = this.state.history.filter((h) => h.ts >= cutoff);
    return this.state.history;
  }

  /** Returns the action taken or why it was skipped. Never throws on a guard. */
  async maybeTopUp(): Promise<{ action: "topped_up" | "skipped"; reason: string; amountSol?: number }> {
    if (this.state.tripped) return { action: "skipped", reason: "breaker tripped — needs manual reset" };

    const balance = (await this.connection.getBalance(this.agentVault, "confirmed")) / LAMPORTS_PER_SOL;
    if (balance >= this.cfg.thresholdSol) return { action: "skipped", reason: "above threshold" };

    const recent = this.recent();
    const last = recent[recent.length - 1];
    if (last && Date.now() - last.ts < this.cfg.minIntervalMs) return { action: "skipped", reason: "rate limited" };
    if (recent.length >= this.cfg.maxTopUpsPerWindow) { this.state.tripped = true; return { action: "skipped", reason: "too many top-ups — tripping breaker" }; }

    let amount = Math.min(this.cfg.targetSol - balance, this.cfg.maxPerTopUpSol);
    const spent = recent.reduce((s, h) => s + h.amountSol, 0);
    const remaining = this.cfg.maxPerWindowSol - spent;
    if (remaining <= 0) { this.state.tripped = true; return { action: "skipped", reason: "window cap reached — tripping breaker" }; }
    amount = Math.min(amount, remaining);
    if (amount <= 0) return { action: "skipped", reason: "amount ≤ 0" };

    const tx = new Transaction().add(SystemProgram.transfer({
      fromPubkey: this.refillSigner.publicKey, toPubkey: this.agentVault,
      lamports: Math.round(amount * LAMPORTS_PER_SOL),
    }));
    tx.feePayer = this.refillSigner.publicKey;
    tx.recentBlockhash = (await this.connection.getLatestBlockhash()).blockhash;

    const sim = await this.connection.simulateTransaction(tx); // SIMULATE FIRST
    if (sim.value.err) return { action: "skipped", reason: `sim failed: ${JSON.stringify(sim.value.err)}` };

    const signed = await this.refillSigner.sign(tx);
    await this.connection.sendRawTransaction(signed.serialize());
    this.state.history.push({ ts: Date.now(), amountSol: amount });
    return { action: "topped_up", reason: "ok", amountSol: amount };
  }

  /** Manual reset — require human investigation before clearing. */
  resetBreaker() { this.state.tripped = false; this.state.history = []; }
}
```

| Guard | Protects against |
| --- | --- |
| threshold / target | Churn (too eager) or stalls (too late) |
| per-top-up cap | One-shot drain of the refill source |
| rolling-window cap | Slow-drip drain across many refills |
| rate limit | Tight loops hammering the source |
| breaker count | Runaway refill cycle (funds leaving as fast as they arrive) |
| **latching** breaker | Stays off until a human investigates |
| simulation | Sending a tx that would fail or move unexpected value |

> The breaker **latches** — a trip almost always means something is wrong (leak, misconfig, or attack). Auto-resetting would defeat the purpose. Alert a human on every trip (see `monitoring-patterns.md`).

## Tier 2: agent proposes a treasury top-up

The agent doesn't move treasury funds — it **proposes** a treasury→agent transfer; operators vote and execute. Requires the agent to be a Proposer member of the treasury multisig.

```ts
import * as multisig from "@sqds/multisig";
import { PublicKey, SystemProgram, TransactionMessage } from "@solana/web3.js";

export async function proposeTreasuryTopUp(p: {
  connection: any; treasuryMultisigPda: PublicKey; treasuryVault: PublicKey;
  agentVault: PublicKey; agentSigner: any; amountSol: number;
}) {
  const info = await multisig.accounts.Multisig.fromAccountAddress(p.connection, p.treasuryMultisigPda);
  const transactionIndex = BigInt(Number(info.transactionIndex) + 1);

  const message = new TransactionMessage({
    payerKey: p.treasuryVault,
    recentBlockhash: (await p.connection.getLatestBlockhash()).blockhash,
    instructions: [SystemProgram.transfer({
      fromPubkey: p.treasuryVault, toPubkey: p.agentVault, lamports: Math.round(p.amountSol * 1e9),
    })],
  });

  await multisig.rpc.vaultTransactionCreate({
    connection: p.connection, feePayer: p.agentSigner, multisigPda: p.treasuryMultisigPda,
    transactionIndex, creator: p.agentSigner.publicKey, vaultIndex: 0, ephemeralSigners: 0,
    transactionMessage: message, memo: `Agent top-up request: ${p.amountSol} SOL`,
  });
  await multisig.rpc.proposalCreate({
    connection: p.connection, feePayer: p.agentSigner, multisigPda: p.treasuryMultisigPda,
    transactionIndex, creator: p.agentSigner,
  });
  // Operators now proposalApprove + vaultTransactionExecute.
  return { transactionIndex: transactionIndex.toString() };
}
```

**Tier sizing:** the micro tier should cover days, not weeks, of routine operation (smaller = safer). The treasury tier kicks in where “oops” would actually hurt. Prefer tying Tier 1 to a Spending Limit over a separate hot wallet — one fewer key to protect.

## Operational notes

- **Idempotency:** on an ambiguous send, check the chain before retrying so you don't double-fund. Record the signature.
- **Keep the refill source small** — its max loss is its balance. Never park the treasury there.
- **Log decisions, not secrets:** `{action, reason, amount, balanceBefore}`.

## Checklist

- [ ] Threshold + target tuned (e.g. refill at 0.05 up to 0.2 SOL)
- [ ] Per-top-up cap, rolling-window cap, and rate limit set
- [ ] Circuit breaker latches and requires manual reset
- [ ] Every top-up simulated before send
- [ ] Large refills go through a treasury proposal, not direct access
- [ ] Refill source sized to bound worst-case loss
- [ ] Trips and top-ups emit alerts

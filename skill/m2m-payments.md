# Machine-to-Machine Payments

> **Load when:** the task involves agents paying each other (or paying/charging services) — direct transfers, escrowed jobs, metered/usage billing, or streamed payments.

Autonomous agents increasingly transact with *other agents and services*: paying for inference, data, compute, an API call, or the output of another agent. Solana is a strong settlement layer for this — sub-second finality, sub-cent fees, native USDC. This file covers M2M patterns from the simplest direct transfer up to escrowed and metered settlement.

All patterns assume the agent spends **under a Squads Spending Limit** (see `squads-identity.md`) so payments are bounded and don't need per-transaction human approval, and that every transfer is **simulated before send** (see `security-principles.md`).

## Choosing a pattern

| Pattern | Use when | Trust model |
| --- | --- | --- |
| **Direct transfer** | Tiny, low-risk, trusted counterparty; pay-after-delivery | Trust the counterparty |
| **Escrow** | Job has value and delivery risk; "pay on completion" | Trust a program/arbiter, not the counterparty |
| **Metered / postpaid** | Usage-based billing (per call, per token, per second of compute) | Periodic settlement; bounded exposure per window |
| **Streaming** | Continuous service (ongoing compute, subscriptions) | Real-time, cancel-anytime flow |

Start simple. Only add escrow/metering when the value at risk justifies the complexity.

## Pattern 1 — Simple direct payment (USDC)

The baseline: agent A pays agent B a fixed amount of USDC for a delivered result. Use SPL token transfers; create the recipient's associated token account (ATA) idempotently.

```ts
import {
  PublicKey,
  TransactionInstruction,
} from "@solana/web3.js";
import {
  getAssociatedTokenAddress,
  createAssociatedTokenAccountIdempotentInstruction,
  createTransferCheckedInstruction,
} from "@solana/spl-token";

const USDC_DECIMALS = 6;

export async function buildUsdcPaymentInstructions(params: {
  feePayer: PublicKey;
  payerVault: PublicKey;     // agent A's Squads vault (source of funds)
  recipient: PublicKey;      // agent B's vault
  usdcMint: PublicKey;
  amountUsdc: number;        // human units, e.g. 0.25
}): Promise<TransactionInstruction[]> {
  const amount = BigInt(Math.round(params.amountUsdc * 10 ** USDC_DECIMALS));
  const fromAta = await getAssociatedTokenAddress(params.usdcMint, params.payerVault, true);
  const toAta = await getAssociatedTokenAddress(params.usdcMint, params.recipient, true);

  return [
    // Idempotent: safe whether or not B's ATA already exists.
    createAssociatedTokenAccountIdempotentInstruction(
      params.feePayer, // fee payer for ATA rent
      toAta,
      params.recipient,
      params.usdcMint
    ),
    createTransferCheckedInstruction(
      fromAta,
      params.usdcMint,
      toAta,
      params.payerVault,       // authority = vault (signed via Squads spending limit)
      amount,
      USDC_DECIMALS
    )
  ];
}
```

> When the source of funds is a Squads vault, these instructions must be executed through the Squads Spending Limit path (`spendingLimitUse`) or a vault transaction. A normal key cannot sign as the vault PDA. Build the Squads transaction from these instructions, sign it through the approved Squads flow, simulate that exact signed transaction, then send with preflight enabled.

### Add a payment reference (reconciliation)

Attach a unique reference so both sides can reconcile a payment to a specific job. A common approach is a deterministic reference key added to the transfer, or a memo instruction:

```ts
import { createMemoInstruction } from "@solana/spl-memo";
// ...
instructions.push(createMemoInstruction(`job:${jobId}`, [params.payerVault]));
```

## Pattern 2 — Escrowed job ("pay on completion")

When the work has value and you don't fully trust the counterparty to deliver, don't pay up front. Use an **escrow**: funds are locked, released on proof of completion, refundable on timeout. Prefer a **battle-tested escrow program** over a hand-rolled one; if you must write your own, keep it minimal and audited.

```
A (payer agent)            Escrow program             B (worker agent)
--------------             --------------             ----------------
lock funds + terms  ──▶   holds funds
                          (deadline, amount,
                           release condition)
                                                 ◄── deliver result + proof
           verify proof / approve  ──▶  release to B
           OR deadline passes      ──▶  refund to A
```

Design rules for agent escrow:

- **Deadline + refund path.** Funds must never be permanently stuck if B disappears. Always include a timeout that returns funds to A.
- **Explicit release condition.** Either A approves, a designated arbiter approves, or an on-chain condition is met. Define it precisely.
- **Cap exposure per job.** One escrow = one bounded amount. Don't pool many jobs into one giant escrow.
- **Idempotent settlement.** Releasing/refunding twice must be impossible.

```ts
// Conceptual interface for an escrow used by agents. Back it with an audited
// on-chain program; this is the shape your agent code calls.
interface AgentEscrow {
  open(params: {
    payerVault: PublicKey;
    worker: PublicKey;
    mint: PublicKey;
    amount: bigint;
    deadlineUnix: number;     // refund to payer after this
    arbiter?: PublicKey;      // optional third party who can release
  }): Promise<{ escrowId: string }>;

  release(escrowId: string): Promise<string>; // -> worker, on completion/approval
  refund(escrowId: string): Promise<string>;  // -> payer, after deadline
}
```

Back production escrow with an audited Solana custody program or a narrowly scoped program you control and have reviewed. Before integration, verify the current audit report, SDK version, cancellation/refund behavior, and how the program enforces per-job caps.

## Pattern 3 — Metered / postpaid billing

For usage-based services (per API call, per 1K tokens, per second of compute), don't settle every unit on-chain — that's slow and wasteful. **Meter off-chain, settle periodically on-chain**, with the on-chain Spending Limit as the hard ceiling.

```ts
class MeteredBilling {
  private accruedUsdc = 0;

  constructor(
    private settleThresholdUsdc: number,   // settle when accrued crosses this
    private maxPerWindowUsdc: number,       // hard cap per window (matches spending limit)
    private pay: (amountUsdc: number) => Promise<string>
  ) {}

  /** Record usage. Returns a settlement signature when a settle is triggered. */
  async record(units: number, pricePerUnitUsdc: number): Promise<string | null> {
    this.accruedUsdc += units * pricePerUnitUsdc;
    if (this.accruedUsdc < this.settleThresholdUsdc) return null;

    const amount = Math.min(this.accruedUsdc, this.maxPerWindowUsdc);
    if (amount <= 0) return null;

    const sig = await this.pay(amount); // simulated + spending-limit-bounded inside
    this.accruedUsdc -= amount;
    return sig;
  }
}
```

Keep the on-chain **Spending Limit** at or below `maxPerWindowUsdc`. Even if the meter is buggy or the counterparty lies about usage, the agent physically cannot overpay beyond its limit.

## Pattern 4 — Streaming payments

For continuous services (an agent renting ongoing compute or a subscription), a **payment stream** flows value per unit time and can be cancelled, so the payer only ever pays for what was consumed. Use an established, audited streaming protocol rather than rolling your own custody logic.

```ts
// Conceptual: start a per-second USDC stream to a service agent, cancel later.
interface PaymentStream {
  start(params: {
    payerVault: PublicKey;
    recipient: PublicKey;
    mint: PublicKey;
    ratePerSecond: bigint;
    maxTotal: bigint;        // hard cap; stream auto-stops here
  }): Promise<{ streamId: string }>;
  cancel(streamId: string): Promise<string>; // stops flow, returns unused funds
}
```

Always set `maxTotal` so a forgotten stream can't drain the vault, and pair it with monitoring (see `monitoring-patterns.md`) so a long-running stream is visible.

## Safety rules for all M2M payments

1. **Bound every payer.** Payments flow under a Squads Spending Limit — the agent can't exceed its per-token, per-window budget no matter what.
2. **Simulate before send.** Always. A failed or surprising simulation aborts the payment.
3. **Allowlist counterparties** for autonomous payments where possible (spending-limit `destinations`, or an app-level allowlist). Unknown recipients require human approval.
4. **Idempotent settlement.** Use references/job IDs so a retry can't double-pay.
5. **Prefer audited programs** for escrow/streaming. Don't hand-roll custody logic for real value.
6. **Cap exposure** per job, per window, and per stream. There is always a hard ceiling.
7. **Log payments, reconcile continuously.** Emit `{counterparty, amount, jobId, signature}` to monitoring; alert on anomalies.

## Checklist

- [ ] Payments execute under a Spending Limit, not unbounded signing authority
- [ ] Every transfer is simulated before send
- [ ] Recipient ATAs created idempotently; references attached for reconciliation
- [ ] Escrow used (with deadline + refund) when delivery risk exists
- [ ] Metered billing caps settlement at the spending-limit ceiling
- [ ] Streams have a `maxTotal` and are monitored
- [ ] Counterparty allowlist enforced for autonomous payments
- [ ] Custody logic relies on audited programs, not bespoke code

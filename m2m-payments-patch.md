## PATCH FOR: skill/m2m-payments.md
## Apply these two targeted edits to the existing file.
## Do NOT replace the whole file — only change what's marked below.

---

### Edit 1 — Pattern 2 (Escrow): add concrete guidance after the AgentEscrow interface

FIND this line (end of the interface block):
```
  refund(escrowId: string): Promise<string>;  // -> payer, after deadline
}
```

REPLACE with:
```
  refund(escrowId: string): Promise<string>;  // -> payer, after deadline
}
```
(no change to the interface itself)

Then ADD the following block immediately after the closing `}`:

---

> **What to back this with:** For production agent-to-agent escrow on Solana, evaluate audited programs rather than writing your own custody logic. At the time of writing, **Streamflow** (https://streamflow.finance) is the most widely used audited protocol for both time-locked escrow and streaming payments on Solana. Review their current audit report at https://docs.streamflow.finance before integrating. For minimal one-off escrow, a tightly-scoped Anchor program you control (and have reviewed) is a valid alternative — keep it under 200 lines and get a peer audit before mainnet.

---

### Edit 2 — Pattern 4 (Streaming): add concrete protocol reference before the interface block

FIND this paragraph:
```
For continuous services (an agent renting ongoing compute or a subscription), a **payment stream** flows value per unit time and can be cancelled, so the payer only ever pays for what was consumed. Use an established streaming protocol rather than rolling your own.
```

REPLACE with:
```
For continuous services (an agent renting ongoing compute or a subscription), a **payment stream** flows value per unit time and can be cancelled, so the payer only ever pays for what was consumed. Use an established streaming protocol rather than rolling your own.

**Recommended protocol:** [Streamflow](https://streamflow.finance) ([docs](https://docs.streamflow.finance)) — audited, actively maintained, supports USDC streams with sender-cancellable flows and a hard `maxTotal` cap. The `@streamflow-finance/stream` SDK integrates with `@solana/web3.js`. Verify the current audit report and SDK version before integrating.
```

---
END OF PATCH

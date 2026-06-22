# Monitoring & Safety Patterns

> **Load when:** the task involves observing the agent in real time — Helius webhooks or MCP, alerting, dashboards, anomaly detection, or building a kill switch.

An autonomous agent you can't see is an incident waiting to happen. Monitoring is not optional: you need **real-time visibility** into every transaction the agent signs, **alerts** on anomalies, and a **kill switch** that can stop it instantly. This file covers Helius-based monitoring (webhooks + MCP) and the patterns for generating *safe* monitoring scripts.

## Principles

1. **Monitoring is read-only by default.** A monitoring script should hold **no signing keys** and have **no ability to move funds**. It observes and alerts. Keep it in a separate process/credential scope from the agent.
2. **Push beats poll for reactions.** Use Helius **webhooks** for instant notification on transactions; use polling only for periodic health checks.
3. **Alert on the unusual, not the routine.** Tune thresholds so humans aren't desensitized. A page should mean "look now."
4. **The kill switch lives in Squads.** The fastest, most reliable stop is revoking the agent's authority on-chain (remove the spending limit / remove the member), not killing a process the agent might restart.

## Helius webhooks: real-time transaction monitoring

Register a webhook for the agent's vault address; Helius pushes every matching transaction to your endpoint. Your endpoint classifies it and alerts.

```ts
// Register a webhook (run once, from an operator context — not the agent).
export async function registerAgentWebhook(params: {
  apiKey: string;
  agentVault: string;       // base58 address to watch
  webhookUrl: string;       // your HTTPS endpoint
  webhookSecret: string;    // sent as the Authorization header
}) {
  const res = await fetch(`https://mainnet.helius-rpc.com/v0/webhooks?api-key=${params.apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      webhookURL: params.webhookUrl,
      transactionTypes: ["ANY"],
      accountAddresses: [params.agentVault],
      webhookType: "enhanced",       // parsed, human-readable payloads
      authHeader: params.webhookSecret,
    }),
  });
  if (!res.ok) throw new Error(`Webhook registration failed: ${res.status}`);
  return res.json();
}
```

```ts
// Receiver: classify + alert. READ-ONLY — no keys, no sends.
import express from "express";

const app = express();
app.use(express.json());

const LARGE_SOL = 0.5;            // alert threshold for SOL movement
const ALERT_DESTINATIONS_DENY = new Set<string>([/* known-bad addresses */]);

app.post("/agent-webhook", (req, res) => {
  // 1. Verify the shared secret before trusting the payload.
  if (req.header("Authorization") !== process.env.WEBHOOK_SECRET) {
    return res.status(401).end();
  }

  for (const tx of req.body as any[]) {
    const sol = (tx.nativeTransfers ?? []).reduce(
      (s: number, t: any) => s + Math.abs(t.amount) / 1e9, 0
    );

    // 2. Anomaly rules — alert, don't act.
    if (sol >= LARGE_SOL) {
      alert("high_value", `Agent moved ${sol} SOL`, tx.signature);
    }
    for (const t of tx.nativeTransfers ?? []) {
      if (ALERT_DESTINATIONS_DENY.has(t.toUserAccount)) {
        alert("denylist", `Transfer to flagged address ${t.toUserAccount}`, tx.signature);
      }
    }
    if (tx.transactionError) {
      alert("tx_error", `Agent tx failed: ${JSON.stringify(tx.transactionError)}`, tx.signature);
    }
  }
  res.status(200).end();
});

function alert(kind: string, message: string, sig: string) {
  // Send to Slack/PagerDuty/Telegram. No on-chain action here.
  console.log(JSON.stringify({ level: "alert", kind, message, sig, ts: Date.now() }));
}
```

### Webhook safety rules

- **Verify the auth header / shared secret** on every request. Webhook endpoints are public; anyone could POST fake events otherwise.
- **The receiver never signs anything.** If an alert warrants action, it pages a human or triggers the kill switch via a *separate, deliberately-gated* path.
- **Make handlers idempotent.** Helius may retry; dedupe on `signature`.

## Helius MCP: investigative monitoring

The **Helius MCP server** lets an operator (or a supervising agent) query chain state conversationally — balances, recent transactions, asset holdings, parsed history — without writing bespoke RPC code. It's ideal for **investigation and health checks**, complementing the always-on webhook stream.

Use MCP for questions like:

- "What has the agent vault done in the last hour?"
- "What's the current SOL + USDC balance and burn rate?"
- "Show failed transactions for this address today."

**MCP for monitoring should use read-only/query tools.** Don't wire a monitoring assistant to anything that can sign or move funds. Keep observation and action strictly separated.

```text
Operator / supervisor agent
        │  (natural language)
        ▼
   Helius MCP server  ──▶  read-only chain queries (balances, txs, assets)
        │
        ▼
   findings → dashboards / alerts / human decision
```

## Generating safe monitoring scripts

When this skill generates a monitoring script, it must follow these constraints — enforce them in review:

1. **No private keys, no signers, no send paths.** If a generated script imports a keypair or calls `sendTransaction`, reject it.
2. **Read-only RPC + webhook only.** `getBalance`, `getSignaturesForAddress`, `getParsedTransaction`, webhook receipt. Nothing that mutates.
3. **Least-privilege credentials.** A scoped Helius API key for reads; the webhook secret; nothing else.
4. **Fail safe and loud.** On error, alert — never silently swallow. A blind monitor is worse than none.
5. **Bounded and rate-limited.** Polling loops have intervals and backoff; don't hammer the RPC.

```ts
// Example of a COMPLIANT health-check script: read-only, alerting, no keys.
import { Connection, PublicKey, LAMPORTS_PER_SOL } from "@solana/web3.js";

const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed"); // read-only key
const VAULT = new PublicKey(process.env.AGENT_VAULT!);
const MIN_SOL = 0.05;

async function healthCheck() {
  try {
    const sol = (await connection.getBalance(VAULT, "confirmed")) / LAMPORTS_PER_SOL;
    if (sol < MIN_SOL) alert("low_balance", `Agent balance ${sol} SOL below ${MIN_SOL}`);

    const sigs = await connection.getSignaturesForAddress(VAULT, { limit: 10 });
    const failed = sigs.filter((s) => s.err);
    if (failed.length) alert("recent_failures", `${failed.length} failed txs in last 10`);
  } catch (e) {
    alert("monitor_error", `Health check failed: ${String(e)}`); // loud, not silent
  }
}

function alert(kind: string, message: string) {
  console.log(JSON.stringify({ level: "alert", kind, message, ts: Date.now() }));
}

setInterval(healthCheck, 60_000); // bounded interval
```

## What to monitor (minimum viable observability)

| Signal | Why | Alert when |
| --- | --- | --- |
| SOL balance | Agent stalls if it runs dry | below threshold (e.g. 0.05 SOL) |
| Token balances | Detect drains / unexpected moves | sudden drop, or below floor |
| Transaction volume | Detect runaway loops | rate spikes above baseline |
| Transaction value | Detect large/unexpected spends | single tx > cap |
| Failed transactions | Detect bugs / attacks | any sustained failures |
| New counterparties | Detect exfiltration | transfer to non-allowlisted address |
| Spending-limit usage | Detect approaching ceiling | > 80% of window budget used |
| Circuit-breaker trips | Funding/spend anomaly | any trip |
| TEE attestation | Detect code/measurement drift | measurement changes |

## The kill switch

When something is wrong, you need to stop the agent **immediately and reliably**. Layered, fastest-first:

```
Layer 1 (seconds, on-chain, authoritative)
  Squads: remove the agent's spending limit and/or remove the member.
  → The agent physically cannot sign value-moving txs anymore.

Layer 2 (process control)
  Stop / pause the agent runtime (kill the TEE deployment, scale to zero).
  → Stops new proposals/activity.

Layer 3 (containment)
  If a key is compromised: rotate the signer (see squads-identity.md),
  sweep funds to a safe vault, freeze treasury proposals.
```

**Layer 1 is the real kill switch.** Killing the process alone isn't enough if the key still has authority — the agent (or an attacker holding the key) could resume elsewhere. Revoking on-chain authority is decisive. Document and rehearse this runbook *before* you need it.

## Checklist

- [ ] Helius webhook registered for the agent vault, with a verified shared secret
- [ ] Webhook receiver is read-only — no keys, no send paths
- [ ] Anomaly alerts wired to a human channel (Slack/PagerDuty/Telegram)
- [ ] Health-check script is read-only, bounded, and fails loud
- [ ] Helius MCP used only with read-only query tools
- [ ] Minimum-viable signals monitored (balance, volume, value, failures, new counterparties)
- [ ] Kill switch documented, Layer-1 (Squads revoke) tested, and rehearsed

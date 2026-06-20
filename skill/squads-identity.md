# Squads Identity & Control

> **Load when:** the task touches the agent's on-chain identity, who can sign, approval flows, or letting the agent transact routinely without a human in the loop.

**Core decision: the agent's identity is a Squads v4 smart account, not a bare keypair.** A keypair is a secret you must protect forever; a smart account is a programmable authority you can govern, rotate, and revoke. If the agent's key leaks, you remove the member and add a new one — the address, balances, token accounts, and history are untouched.

| Concern | Bare keypair | Squads smart account |
| --- | --- | --- |
| Address stability | Dies with the key | Stable PDA, survives signer changes |
| Key compromise | Total loss | Revoke signer, keep identity |
| Authority | All-or-nothing | Roles + per-token spending limits |
| Treasury separation | None | Treasury gates large spends |
| Auditability | Just a pubkey | On-chain proposals, votes, executions |

## Roles (use correct v4 terminology)

Squads v4 assigns each member a permission set. Three matter for agents:

- **Proposer** (`Permission.Initiate`) — creates proposals, cannot approve/execute. **Default role for an agent.**
- **Voter** (`Permission.Vote`) — approves/rejects. Reserved for human operators. **Agents are not Voters.**
- **Executor** (`Permission.Execute`) — executes a proposal that already reached threshold. Optionally grant the agent this so approved actions execute without a human clicking “execute.”

> ⚠️ Never give an agent `Permissions.all()`. Proposer (optionally + Executor) only.

```ts
import * as multisig from "@sqds/multisig";
const { Permission, Permissions } = multisig.types;

const agentProposer = Permissions.fromPermissions([Permission.Initiate]);
const agentProposerExecutor = Permissions.fromPermissions([Permission.Initiate, Permission.Execute]);
const operator = Permissions.all(); // humans only
```

**Recommended membership** (threshold = 2): two human operators with `all()`, one agent signer as Proposer (+ optional Executor). The agent can *propose* anything; moving real value needs operator votes. For routine low-value work, use Spending Limits instead of widening the role.

## Create the smart account

```ts
import { Connection, Keypair, PublicKey } from "@solana/web3.js";
import * as multisig from "@sqds/multisig";
const { Permission, Permissions } = multisig.types;

const connection = new Connection(process.env.HELIUS_RPC_URL!, "confirmed");

// `creator` is a human/deployer key used ONCE. The agent signer is just a member.
export async function createAgentSmartAccount(p: {
  creator: Keypair; operatorA: PublicKey; operatorB: PublicKey; agentSigner: PublicKey;
}) {
  const createKey = Keypair.generate();
  const [multisigPda] = multisig.getMultisigPda({ createKey: createKey.publicKey });
  const programConfigPda = multisig.getProgramConfigPda({})[0];
  const programConfig = await multisig.accounts.ProgramConfig.fromAccountAddress(connection, programConfigPda);

  const signature = await multisig.rpc.multisigCreateV2({
    connection, createKey, creator: p.creator, multisigPda,
    configAuthority: null,        // controlled by its own members
    timeLock: 0, threshold: 2,    // 2 human approvals for non-limited txs
    treasury: programConfig.treasury, rentCollector: null,
    members: [
      { key: p.operatorA, permissions: Permissions.all() },
      { key: p.operatorB, permissions: Permissions.all() },
      { key: p.agentSigner, permissions: Permissions.fromPermissions([Permission.Initiate]) },
    ],
    sendOptions: { skipPreflight: false }, // keep preflight = simulate
  });

  const [vaultPda] = multisig.getVaultPda({ multisigPda, index: 0 });
  return { multisigPda, vaultPda, signature };
}
```

> The **vault PDA (index 0) is the agent's address.** Fund it, give it token accounts, point integrations at it. The signer key is replaceable; the vault is forever.

## Spending Limits: autonomy without constant approvals

A Spending Limit lets a member move up to *N* of one token per time window (day/week/month) **without** the propose→vote→execute cycle. This is how an agent pays for inference, gas, and small swaps unattended — under a hard, on-chain ceiling that resets on schedule. Anything above still requires a full proposal.

```ts
import { PublicKey, Keypair } from "@solana/web3.js";
import * as multisig from "@sqds/multisig";
const { Period } = multisig.types;

// Agent may spend up to 5 USDC/day, no approvals. Adding a limit is itself a
// config action requiring operator threshold — the agent can't widen its own.
export async function addUsdcDailyLimit(p: {
  connection: any; feePayer: any; multisigPda: PublicKey; agentSigner: PublicKey; usdcMint: PublicKey;
}) {
  const createKey = Keypair.generate();
  const [spendingLimitPda] = multisig.getSpendingLimitPda({ multisigPda: p.multisigPda, createKey: createKey.publicKey });
  return multisig.rpc.multisigAddSpendingLimit({
    connection: p.connection, feePayer: p.feePayer, multisigPda: p.multisigPda,
    spendingLimit: spendingLimitPda, createKey: createKey.publicKey, rentPayer: p.feePayer,
    vaultIndex: 0, mint: p.usdcMint,
    amount: 5_000_000n,            // 5 USDC (6 decimals)
    period: Period.Day,
    members: [p.agentSigner],
    destinations: [],             // [] = any; ALLOWLIST in production
    memo: "Agent daily inference + gas budget",
  });
}
```

**Design guidance:** separate budgets per purpose (gas vs services); allowlist `destinations` in production; right-size the window so worst-case loss = one window's budget; the agent cannot raise its own limit (that's the point).

## The production default: big vs small

```
Routine (≤ limit)            Significant (> limit)
agent spends directly   →    agent PROPOSES
under Spending Limit         operators VOTE (threshold)
(no human needed)            agent (Executor) or operator EXECUTES
```

Spending Limit handles the ~95% of routine transactions; Proposer role queues the ~5% that matter; optional Executor lets approved proposals self-execute.

## Rotate / revoke a compromised signer

The identity survives — operators propose `multisigRemoveMember(oldKey)`, then `multisigAddMember(newKey, Initiate)`, then re-create spending limits for the new key. Vault address, balances, and history are unchanged. Update the runtime to load the new signer (ideally re-sealed in its TEE — see `tee-deployment.md`).

## Checklist

- [ ] Identity is a Squads v4 vault PDA, not a raw keypair
- [ ] Agent is **Proposer** only (optionally + Executor), never `all()`
- [ ] Human operators hold Voter rights; threshold ≥ 2 for value-moving txs
- [ ] Routine spend covered by a tight Spending Limit (per token + window)
- [ ] Spending-limit `destinations` allowlisted in production
- [ ] Signer-rotation runbook documented
- [ ] Preflight/simulation enabled on all config calls

**Next:** where the signer key lives → `tee-deployment.md` · keeping the vault funded → `self-funding.md`

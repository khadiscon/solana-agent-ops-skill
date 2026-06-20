# Resources

> **Load when:** you need authoritative links for SDKs, docs, RPC, or tooling in the 2026 Solana agent-ops stack. Always prefer the upstream docs over memory — APIs move.

Links change and APIs evolve. Treat this as a starting map; verify versions against the upstream docs before pinning.

## Core: actions layer (what this skill governs)

- **Solana Agent Kit** — the actions layer for agents (swap, stake, transfer, mint, deploy, lend, …): https://github.com/sendaifun/solana-agent-kit
- **Solana Agent Kit docs** — https://docs.sendai.fun

## Solana client & program tooling

- **@solana/kit** (web3.js 2.x, the modern client): https://github.com/anza-xyz/kit
- **Solana web3.js docs**: https://solana.com/docs/clients/javascript
- **@solana/spl-token**: https://spl.solana.com/token
- **Anchor** (programs): https://www.anchor-lang.com
- **Solana developer docs**: https://solana.com/docs

## Identity & control: Squads v4

- **Squads**: https://squads.so
- **Squads developer docs**: https://docs.squads.so
- **@sqds/multisig** (Smart Account Program SDK): https://github.com/Squads-Protocol/v4
- Key concepts: smart account (PDA) as identity · members + permissions (Initiate/Vote/Execute) · thresholds · **Spending Limits** (per mint + period) · vault transactions · proposals.

## RPC, data, webhooks, MCP: Helius

- **Helius**: https://helius.dev
- **Helius docs**: https://docs.helius.dev
- **Webhooks** (real-time, enhanced/parsed transactions): https://docs.helius.dev/data-streaming/webhooks
- **Enhanced Transactions API** (human-readable history): https://docs.helius.dev
- **Helius MCP server** (conversational, read-only chain queries for monitoring/investigation): https://github.com/helius-labs (check for the current MCP server repo)

## Confidential execution: TEEs

### Marlin Oyster (Intel TDX)

- **Marlin docs**: https://docs.marlin.org
- **Oyster** (confidential compute / CVMs, sealed enclaves, remote attestation): https://www.marlin.org
- Concepts: reproducible enclave images · in-enclave key generation · Intel TDX · remote attestation (RA) over measurement.

### Phala Network (dstack + CVMs)

- **Phala**: https://phala.network
- **Phala docs**: https://docs.phala.network
- **dstack** (deploy containerized apps to Confidential VMs): https://github.com/Dstack-TEE/dstack
- Concepts: CVMs · verifiable execution · remote attestation reports · **private inference** · strong **Eliza** integration.

### TEE-based agent projects (orientation, verify independently)

- **KobotoAI** — TEE-secured agent infrastructure.
- **Magic Newton** — agent framework using confidential execution.
- **Spore.fun**–style agents — autonomous, self-sustaining agents secured by TEEs.

*(These illustrate the pattern; confirm each project's current design and claims yourself.)*

## Agent frameworks

- **Eliza** (TS agent framework, strong TEE/Phala support): https://github.com/elizaOS/eliza
- **Eliza docs**: https://eliza.how

## Payments

- **SPL Token** (USDC transfers, ATAs): https://spl.solana.com/token
- **Circle / USDC on Solana**: https://developers.circle.com
- For escrow/streaming, prefer **audited** programs over hand-rolled custody. Evaluate current options (e.g. streaming-payment protocols) and review their audits before use.

## Security references

- **Solana program security best practices**: https://solana.com/developers/courses
- **Squads security model / docs**: https://docs.squads.so
- **Intel TDX overview**: https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html
- General: pin dependencies, use lockfiles, minimize the signer's dependency surface, audit anything that touches custody.

## How to keep this current

- **Pin versions** in your project and re-check upstream changelogs before upgrading.
- **APIs > memory.** When a code sample here disagrees with current upstream docs, the docs win.
- **Re-verify TEE platforms** — the confidential-compute space moves fast; measurements, SDKs, and attestation formats change.

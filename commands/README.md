# Commands

Five guided, safety-gated workflows for common agent-ops tasks. Each loads the right skill files, asks for the inputs it needs, simulates before sending, and stops on anything risky.

| Command | Purpose |
| --- | --- |
| **/setup-squad** | Create a Squads v4 smart account as the agent's identity, with roles + spending limits |
| **/fund-agent** | Configure threshold-based self-funding with caps and a latching circuit breaker |
| **/deploy-tee** | Deploy to Marlin Oyster or Phala with attestation-gated signer registration |
| **/monitor-agent** | Stand up Helius webhooks + a read-only health monitor + a tested kill switch |
| **/audit-agent** | Run the pre-mainnet security audit against the non-negotiables |

Every command obeys the always-on `rules/` and the `skill/security-principles.md` non-negotiables.

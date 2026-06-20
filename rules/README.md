# Rules

Always-on engineering rules that apply to **all** code and designs produced with this skill. Unlike the `skill/` knowledge files (loaded on demand) and `commands/` (invoked deliberately), rules are ambient constraints. They encode the non-negotiables so safety doesn't depend on remembering to load a file.

| Rule file | Scope |
| --- | --- |
| **key-management.md** | How keys are created, stored, used, and rotated — never in env/disk |
| **transaction-safety.md** | Simulation, idempotency, least privilege, multisig gating |
| **solana-ops.md** | Stack conventions, devnet-first, dependency hygiene, logging |

If a request conflicts with a rule, stop and explain rather than complying.

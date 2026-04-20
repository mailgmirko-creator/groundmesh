# Light Node Agent v1

This folder holds tracked public examples for the first GroundMesh light node role.

Tracked here:
- `manifest.sample.json`
- `heartbeat.sample.json`
- `assignment.sample.json`
- `claim.sample.json`
- `ack.sample.json`
- `result.sample.json`

Machine-local runtime files belong under:
- `private/node_agent/`

Recommended local workflow:

```powershell
.\scripts\node-agent-init.ps1 -Country Montenegro -City Tivat
.\scripts\node-heartbeat.ps1
.\scripts\node-assignment-sync.ps1
.\\scripts\\node-assignment-claim.ps1
.\scripts\node-public-state-sync.ps1
.\scripts\node-assignment-result.ps1
.\scripts\node-assignment-ack.ps1
.\scripts\node-agent-validate.ps1
```

GroundMesh intent for v1:
- visible capability declaration
- bounded non-sensitive work only
- refusal is healthy
- no arbitrary remote shell ownership
- inbox, claim, outbox, and ack trails stay inspectable

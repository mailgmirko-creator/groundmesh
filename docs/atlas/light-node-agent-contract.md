# GroundMesh Light Node Agent Contract v1

## Purpose
This note defines the first honest contract for a lightweight GroundMesh node.

It is intentionally small. A light node is not a sovereign steward node, not a hidden remote shell,
and not a vague promise of future decentralization. It is the smallest safe participant that can:

- join visibly
- declare limited capability
- receive low-risk work
- refuse unsafe requests
- pause without penalty

This note translates the architecture in `Seed / Trust / Mesh / Edge` into a first buildable node role.

## Canonical v1 files
Tracked public examples:

- `agents/light-node/manifest.sample.json`
- `agents/light-node/heartbeat.sample.json`
- `agents/light-node/assignment.sample.json`
- `agents/light-node/claim.sample.json`
- `agents/light-node/ack.sample.json`
- `agents/light-node/result.sample.json`
- `docs/data/public-node-inbox.json`
- `docs/data/public-node-outbox.json`
- `docs/data/public-node-claims.json`
- `docs/data/public-node-acks.json`

Machine-local generated files:

- `private/node_agent/node-manifest.local.json`
- `private/node_agent/node-heartbeat.latest.json`
- `private/node_agent/public-node-inbox.latest.json`
- `private/node_agent/public-node-outbox.latest.json`
- `private/node_agent/public-node-claims.latest.json`
- `private/node_agent/public-node-acks.latest.json`
- `private/node_agent/workspace/`
- `private/node_agent/node-agent.log`

Supporting scripts:

- `scripts/node-agent-init.ps1`
- `scripts/node-heartbeat.ps1`
- `scripts/node-assignment-sync.ps1`
- `scripts/node-assignment-claim.ps1`
- `scripts/node-public-state-sync.ps1`
- `scripts/node-assignment-result.ps1`
- `scripts/node-assignment-ack.ps1`
- `scripts/node-agent-validate.ps1`

## Why this comes first
GroundMesh needs a real node shape before it can truthfully say that distributed participation exists.

The first node contract should optimize for:

- legibility
- reversibility
- low trust burden
- low blast radius
- graceful refusal

It should **not** optimize for maximum power in v1.

## Definition
A **Light Node Agent** is a client-first, consent-first GroundMesh runtime that runs on a desktop,
mini-PC, home server, or similar device and performs only bounded, non-sensitive tasks.

In v1 it is allowed to:

- register capability declarations
- send heartbeat and health status
- pull public state and cache it locally
- run explicitly allowed low-risk jobs
- publish auditable job results
- pause, refuse, or disconnect

In v1 it is **not** allowed to:

- receive arbitrary shell execution from the network
- hold unique trust authority
- publish site or policy changes on its own
- handle secrets by default
- do hidden surveillance or background capture
- become required for system continuity

## GroundMesh constraints carried into the node
This contract follows existing repo values:

- `TP-03`: no compulsion, no pressure-based continuity
- `GM-INV-VIII`: pause is not failure
- command-contract logic: execution must be scoped, safeguarded, and inspectable
- thought-signal logic: interpretation hygiene should run locally before stronger action

## Node classes in v1

### 1. Edge client
- mostly consumes public state
- may send heartbeat
- may cache local content
- no assigned work required

### 2. Light node
- receives bounded public or low-risk tasks
- reports basic capacity and availability
- may contribute compute, cache, or relay work

### 3. Steward node
- out of scope for this contract
- higher trust and review burden

This note covers **Light node** only.

## Lifecycle

### State 1: Local only
Node exists on-device but is not yet registered.

### State 2: Declared
Node sends a capability declaration and requests participation.

### State 3: Accepted
Seed or trust layer accepts the node for a bounded role.

### State 4: Active
Node may receive allowed assignments.

### State 5: Paused
Node is temporarily unavailable by user choice, system policy, or low-resource conditions.

### State 6: Revoked
Node is refused future work until reviewed.

## Capability declaration
The light node should declare only what GroundMesh actually needs to route safe work.

Recommended declaration fields:

```json
{
  "protocol_version": "gm.node.v1",
  "agent_version": "0.1.0",
  "node_id": "node-local-generated-or-seed-issued",
  "node_class": "light",
  "device_class": "desktop",
  "display_name": "Mirko-Tivat-Desk-01",
  "operator": {
    "name": "Mirko Giljaca",
    "consent_mode": "explicit"
  },
  "location_hint": {
    "country": "Montenegro",
    "city": "Tivat"
  },
  "capabilities": {
    "cpu_cores": 8,
    "memory_gb": 16,
    "storage_free_gb": 120,
    "can_cache_public_state": true,
    "can_run_local_model": false,
    "can_relay_bandwidth": true,
    "can_accept_background_jobs": true
  },
  "limits": {
    "max_job_minutes": 15,
    "max_cpu_percent": 35,
    "network_mode": "metered-safe",
    "energy_mode": "prefer-plugged-in"
  },
  "consent": {
    "public_state_sync": true,
    "public_cache": true,
    "public_health_probe": true,
    "non_sensitive_compute": false
  }
}
```

## Heartbeat
Heartbeat should be small, boring, and useful.

Recommended fields:

```json
{
  "protocol_version": "gm.node.v1",
  "node_id": "node-0001",
  "ts_utc": "2026-04-17T10:30:00Z",
  "status": "active",
  "availability": "accepting_public_work",
  "resources": {
    "cpu_load": 0.21,
    "memory_free_gb": 9.8,
    "storage_free_gb": 118.2
  },
  "network": {
    "reachable": true,
    "latency_class": "normal"
  },
  "jobs": {
    "running": 0,
    "completed_since_boot": 5,
    "last_result": "ok"
  }
}
```

## Allowed v1 job classes
Only low-risk classes should exist at first.

### Allowed
- `public_state_sync`
  Pull public metrics, node ledger snapshots, and non-sensitive manifests.
- `public_cache_refresh`
  Cache known public resources for faster local or regional access.
- `public_health_probe`
  Check a public endpoint and report reachability or latency.
- `local_tsl_assessment`
  Run local interpretation or balancing logic on node-local, user-approved inputs.
- `non_sensitive_batch`
  Explicitly approved lightweight compute that does not require secrets or privileged write access.

### Not allowed in v1
- arbitrary shell command execution
- remote filesystem mutation outside agent workspace
- secret-bearing deploy tasks
- privileged moderation actions
- autonomous policy changes
- stealth background persistence
- microphone, camera, or device-wide telemetry without clear explicit opt-in

## Assignment envelope
Every assigned task should be bounded by a small envelope:

```json
{
  "assignment_id": "asg-0001",
  "job_class": "public_state_sync",
  "contract_id": "CC.light_node_sync_public_state.v1",
  "issued_by": "seed-reference-node",
  "issued_at": "2026-04-17T10:32:00Z",
  "expires_at": "2026-04-17T10:47:00Z",
  "payload": {
    "sources": [
      "docs/data/metrics.json",
      "docs/ledger/data/nodes.json"
    ],
    "max_download_kb": 512
  }
}
```

## Refusal rules
The node must refuse work when any of these are true:

- job class is not explicitly allowed
- contract id is missing or unknown
- assignment is expired
- local consent for that job class is false
- resource limits are exceeded
- task requires secrets the node does not hold
- payload scope exceeds declared permissions
- local operator has paused the node

Refusal is a healthy action, not a failure state.

## Local autonomy rules
The node operator must always be able to:

- pause work
- reduce limits
- revoke consent for a job class
- inspect recent jobs
- clear local cache
- uninstall the agent cleanly

GroundMesh must not design the light node as an always-obedient servant.

## Data boundary in v1
Public-by-default for first tasks:

- public metrics
- public node ledger snapshots
- public manifests
- public documentation bundles

Sensitive by default and out of scope unless separately designed:

- private registration data
- credentials
- steward-only policy material
- undeclared personal telemetry
- confidential local files

## Trust boundary in v1
The light node is a worker and participant, not a trust root.

That means:

- seed or trust layer may accept or revoke a node
- node may attest what it did
- node may not become sole authority for system truth
- multiple nodes may mirror state later, but this contract does not pretend that already exists

## First command contract binding
The first safe moral-action binding for a light node should be:

- `CC.light_node_sync_public_state.v1`

The next safe complementary binding is:

- `CC.light_node_claim_public_assignment.v1`

The next safe complementary binding after the claim step is:

- `CC.light_node_report_public_result.v1`

The next safe complementary binding after the result step is:

- `CC.light_node_ack_public_assignment.v1`

This keeps the first multi-node coordination move honest:

- append-only claim trail
- append-only acknowledgement trail
- bounded claim TTL
- no hidden lock manager
- no privileged queue mutation
- visible ownership before result publication
- visible closure after result publication

That gives GroundMesh a first coordination surface without pretending that full distributed scheduling already exists.

This is a bounded task:

- pull public state
- record an append-only claim before execution
- cache only in local agent workspace
- record the bounded result
- acknowledge the claim resolution without mutating the original claim
- no privileged writes
- no secret material
- auditable
- rate-limited
- dry-run first

That gives GroundMesh one real command path without opening the door to “remote machine ownership.”

## Immediate implementation implications
This contract implies the next practical pieces:

1. a local node manifest file
2. a heartbeat format
3. a workspace directory the node is allowed to write to
4. a tiny seed endpoint or file-based queue for public assignments
5. one visible local log for inspections and refusal reasons

Those pieces now exist in a first file-based form:

- a public inbox feed under `docs/data/public-node-inbox.json`
- a public claims feed under `docs/data/public-node-claims.json`
- a public outbox feed under `docs/data/public-node-outbox.json`
- a public acknowledgement feed under `docs/data/public-node-acks.json`
- a local inbox sync script for bounded assignment pull
- a local claim script for append-only assignment ownership
- a local outbox result script for bounded result recording
- a local acknowledgement script for append-only claim closure

## Plain-language summary
The first light node should feel like this:

> “I can join. I can help. I can show what I am.  
> I can do a small set of honest tasks.  
> I can refuse what I did not consent to.  
> I do not become dominated by the system I serve.”

That is a strong beginning for GroundMesh.

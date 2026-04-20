# GroundMesh Architecture: Seed / Trust / Mesh / Edge

## Why this note exists
Two earlier framings turned out to be the same architecture seen from two angles:

- `named components + install lanes + staged rollout` is the **execution view**
- `Seed / Trust / Mesh / Edge` is the **structure view**

This note combines both so GroundMesh has one concrete map instead of two half-maps.

## Core answer
GroundMesh should **not** depend forever on a permanent sovereign core.

GroundMesh **does** need a bootstrap center at first:

- to publish releases
- to coordinate registration and first trust
- to recover from failure
- to keep drift low while the system is still young

So the right target is:

> **temporary seed-centered coordination, progressive decentralization, and eventual non-irreplaceability**

Mirko as origin is compatible with GroundMesh outgrowing Mirko as runtime center.

## Why not choose one extreme

### Fully centralized from the start
Strengths:
- easiest to launch
- easiest to debug
- easiest to moderate
- easiest to keep version alignment

Risks:
- single point of failure
- easier capture
- cost and stewardship burden pile onto one node
- can become the opposite of the values it claims

### Fully distributed from the start
Strengths:
- resilient in principle
- naturally anti-capture
- aligned with commons logic
- stronger as more nodes join

Risks:
- hard node discovery
- hard trust bootstrapping
- hard update coordination
- hard abuse handling
- hard job routing under churn
- hard recovery when many weak nodes disagree

## Recommended shape
GroundMesh should split into four layers:

## 1. Seed
Purpose: start, anchor, publish, and recover.

This is not a forever throne. It is the first stable root.

Named components:
- `Reference Node`
- `Public Gateway`
- `Bootstrap Registry`
- `Release Signer`
- `Steward Console`

What belongs here at first:
- public website / PWA entry point
- first registration path
- node directory bootstrap
- release manifests and signed updates
- initial policy publication
- emergency pause / revoke capability

What should leave this layer over time:
- unique control of trust
- unique control of routing
- unique control of storage
- unique control of compute scheduling

## 2. Trust
Purpose: decide what can be believed, accepted, or acted on.

Trust is not just identity. It is consent, provenance, attestation, review, and graceful exit.

Named components:
- `Consent Ledger`
- `Attestation Ledger`
- `Node Reputation Trail`
- `Policy Bundle`
- `Plural Review Path`

What belongs here:
- registration consent and capability declarations
- signed node identity or steward-backed trust bootstrap
- event attestation
- moderation and review pathways
- quorum or steward review for sensitive actions
- rollback and deprecation rules

GroundMesh value: trust must become harder to fake without becoming harder to join with dignity.

## 3. Mesh
Purpose: carry real work across many nodes.

This is where GroundMesh becomes stronger as participation grows.

Named components:
- `Job Router`
- `Work Queue`
- `Ledger Mirrors`
- `State Replicas`
- `Model Worker Pool`
- `Resource Directory`

What belongs here:
- distributed compute execution
- replication and caching
- model inference on capable nodes
- bandwidth-aware routing
- synchronization of non-sensitive shared state
- node health and capacity reporting

Important rule:
- the mesh should carry work as early as possible
- the seed should carry authority only as long as necessary

## 4. Edge
Purpose: meet people and lightweight devices where they are.

The edge is not weak. It is where participation becomes real.

Named components:
- `GroundMesh PWA`
- `Mobile Client`
- `Desktop Client`
- `Light Node Agent`
- `Local Cache`

What belongs here:
- registration and contact flows
- maps, dashboards, messages, and local notices
- local-first interaction
- optional low-impact contribution
- selective sensing, caching, or relay functions

Important rule:
- phones are excellent clients
- phones are not the first place to anchor the mesh backbone

## Where current GroundMesh pieces fit
- `docs/` public site and future PWA -> `Seed` and `Edge`
- `balance_engine/` -> `Trust` and node-local `Mesh` decision support
- `apps/tsl/` -> local and shared interpretation discipline across `Trust` and `Mesh`
- `docs/protocols/TP-03.md` and `docs/invariants/GM-INV-VIII.md` -> `Trust` constraints
- `docs/echo_archive/EA-0001_soul-and-system.md` -> philosophical grounding for behavior under imbalance

The recent thought-signal work belongs here too:
- interpretation hygiene should run locally at nodes before stronger action
- not only at a central authority

## Install lanes
GroundMesh should not ship as one giant install. It should have clear lanes.

### Lane A: Public participant
- install nothing
- use the site or PWA
- can register, read, signal interest, follow updates

### Lane B: Light client
- install the PWA or small desktop/mobile app wrapper later if needed
- can receive notifications, sync local state, and participate more smoothly

### Lane C: Node contributor
- install a lightweight node agent on desktop, mini-PC, home server, or edge box
- can contribute compute, storage, cache, relay, or model work

### Lane D: Steward / reference node
- run the reference node stack
- publish releases
- mirror trust data
- perform recovery and review tasks

## Staged rollout

### Phase 0: Seed reality
- Mirko-centered origin
- one public gateway
- one release path
- one bootstrap registry
- no claim of full decentralization yet

### Phase 1: Invited node growth
- first trusted external nodes join
- node capabilities begin to register
- non-sensitive workloads start distributing
- trust remains mostly steward-backed

### Phase 2: Mirrored trust
- at least two or three steward-capable mirrors
- replicated ledgers
- multiple review paths
- seed no longer equals single machine

### Phase 3: Working mesh
- distributed job routing
- replicated shared state
- model work runs across capable nodes
- graceful degradation if one steward node disappears

### Phase 4: Federated GroundMesh
- no irreplaceable single root
- trust decisions can be plural
- multiple public gateways
- Mirko can step back without GroundMesh collapsing

## Design rules
- No function should remain single-home forever unless there is a clear safety reason.
- Every central function should have a migration path to mirror, quorum, or federation.
- Seed authority is acceptable only when it is explicit, reversible, and shrinkable.
- Trust should decentralize more slowly than compute.
- Compute should decentralize more slowly than public access.
- Public access should be easiest of all.
- Edge devices should default to client-first roles and earn heavier roles by demonstrated capacity.
- Energy generation and physical resilience matter, but they should plug into the mesh as resource classes, not define the software architecture.

## What this means in plain GroundMesh terms
GroundMesh does not need a permanent `Core`.

GroundMesh does need:
- a `Seed` at first
- a `Trust` layer that cannot be hand-waved
- a `Mesh` layer that grows with participation
- an `Edge` layer that lets almost anyone join

That gives us a cleaner sentence than "core vs no core":

> Start centered enough to survive.  
> Distribute enough to become real.  
> Design every center so it can eventually be outgrown.

## Immediate next build implication
The next concrete software target should be:

1. strengthen the public site/PWA as the universal edge
2. define the first lightweight node agent contract
3. keep trust and registration stewarded for now
4. distribute non-sensitive compute before distributing sensitive authority

This is the smallest realistic path from "origin through Mirko" to "GroundMesh continues without requiring Mirko's machine to stay on forever."

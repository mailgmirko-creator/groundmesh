# One Tiny End-to-End Loop (GroundMesh Breathing Test)

## Goal

Prove GroundMesh is operationally alive with one harmless, bounded assignment cycle from publish to visible result.

## Loop definition

1. **Seed publishes one public assignment envelope**
   - Envelope includes: task id, allowed action, timeout, expected output schema.
2. **One light node fetches assignment**
   - Node records fetch time and envelope id.
3. **Node writes receipt to local inbox**
   - Creates immutable local record before execution.
4. **Node performs one bounded harmless task**
   - Example: fetch a public status file, transform into a normalized summary.
5. **Node writes result to outbox**
   - Include result payload, execution metadata, and checksum.
6. **Result is validated and shown in public view**
   - Validation checks schema and envelope match.
   - Public page shows task id, node id alias, timestamp, status.

## Constraints

- No privileged machine actions.
- No credential-required endpoints.
- No side effects outside local scratch/output paths.
- Clear timeout and retry behavior.

## Minimum artifacts

- Assignment envelope schema.
- Inbox/outbox file formats.
- Result validator script.
- Public status renderer (static snapshot or generated JSON view).

## Success criteria

- Same envelope can be processed repeatably without ambiguity.
- Validation fails safely on malformed results.
- Public view updates only from validated outputs.
- Full loop can run from clean state with one command sequence.

## Why this matters

This loop prevents architecture drift. It forces contracts, observability, and trust posture to be exercised by runnable reality before adding complexity.

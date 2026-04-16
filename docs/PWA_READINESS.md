# PWA Readiness Note

## Purpose

This note defines the minimum viable PWA posture for the GroundMesh public front door on GitHub Pages.

Ground rule: the PWA is a universal access layer, not the full GroundMesh runtime.

## What the PWA should provide now

- Installable public front door across modern mobile and desktop browsers.
- Fast repeat visits through cached static assets.
- Basic offline readability for key orientation pages.
- Honest network-state signaling when dynamic data cannot load.

## Required pieces

1. **Web app manifest**
   - Name, short name, icons, theme/background colors, display mode, start URL, scope.
2. **Service worker**
   - Cache static shell and core pages.
   - Use a safe cache strategy (cache-first for immutable assets, network-first for live status).
3. **HTTPS hosting**
   - Satisfied by GitHub Pages.
4. **Install and fallback UX**
   - Clear install affordance where browser supports it.
   - Clear fallback for browsers that do not expose install prompts.

## Cache boundaries

Safe to cache aggressively:

- Static HTML/CSS/JS assets.
- Public non-sensitive docs and glossary content.

Cache cautiously (short TTL or network-first):

- Status dashboards and registry snapshots.
- Any data that indicates current network health.

Never treat as offline-authoritative:

- Operational truths that require current trust-state validation.
- Any sensitive or privileged control data.

## GitHub Pages fit

GitHub Pages is appropriate for:

- Public front door.
- Public orientation docs.
- Installable PWA shell.

GitHub Pages is not the place for:

- Secret storage.
- Private write APIs.
- Long-running coordination jobs.
- Trusted signing workflows.

## Relationship to node agents

- PWA: discover, read, orient, lightweight interaction.
- Node agent: execute bounded tasks, maintain durable participation, handle signed/verified flows.

The PWA can visualize mesh state and submit low-risk public input, while node agents carry durable participation responsibilities.

## Readiness checklist

- [ ] Manifest is complete and versioned.
- [ ] Service worker scope is explicit and tested.
- [ ] Offline mode shows accurate capability limits.
- [ ] Dynamic views degrade gracefully when offline.
- [ ] Public/private boundary is documented and enforced.
- [ ] Cache invalidation strategy is documented.

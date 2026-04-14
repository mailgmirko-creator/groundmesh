# 0005 — Public Registration Begins as a Pilot
Date: 2026-04-14T20:55:00Z
Status: Accepted

## Context
GroundMesh aims to eventually support real public participation at much greater scale, including
some form of registration or declared joining. That step matters, but the current public docs
surface is still intentionally simple:

- it is a public trust and orientation layer
- it is not yet a hardened intake system
- it does not yet have a full moderation, verification, or sensitive-data handling layer

The repo already says this in several places, but those warnings are scattered. GroundMesh now
needs one clear answer for how registration should begin when the time comes.

## Decision
Do not open broad public registration all at once.

When GroundMesh first allows registration or declared joining beyond simple public contact, it
should begin as a narrow pilot with explicit limits and review gates.

The working model is:

1. Start with a pilot, not a planetary launch.
   - Limit scope by cohort, circle, geography, or invitation path.
   - Keep the first promise smaller than the eventual mission.
2. Keep the static public docs layer separate from sensitive intake.
   - Public pages may describe the path and direct people toward it.
   - Identity, moderation, consent records, and confidential handling should live in a separate
     intake surface when they become real.
3. Do not collect more than the current purpose requires.
   - Ask for the minimum information needed.
   - Prefer reversible, low-exposure participation paths where possible.
4. Do not launch the pilot until the registration readiness checklist is honestly green.
   - Moderation, consent, privacy, removal/correction, response ownership, and rollback must all
     be defined before opening the door.

## Consequences

- GroundMesh preserves trust by refusing to promise more handling capacity than it actually has.
- Public registration becomes a tested operational path rather than a symbolic announcement.
- The project can learn from a smaller cohort before carrying wider human consequence.
- The public docs site remains honest and useful without being forced to become a confidential
  system prematurely.

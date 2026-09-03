# GroundMesh Licensing Notes

Status: Plain-language clarification
Review date: 2026-09-03

## Short Version

GroundMesh currently uses the Tranquility Commons License - NoDerivatives 1.0 (`TCL-ND-1.0`). It is a custom source-available commons license. It is not an OSI-approved open-source license.

Do not describe the repository as "open source" unless the license is changed through a guarded review. Safer wording is "public source," "source-available," "public documentation," or "commons-stewarded under TCL-ND-1.0."

## Why This Matters

The Open Source Definition requires, among other things, permission for redistribution and derived works. TCL-ND-1.0 is intentionally stricter: it forbids commercial use and public modified versions except through the canonical upstream project.

That may fit GroundMesh's current stewardship goals, but it means ordinary open-source assumptions do not apply.

Reference: https://opensource.org/osd

## GitHub Visibility Is Separate

A public GitHub repository grants GitHub and other GitHub users platform permissions described in GitHub's terms, including viewing and forking public content through GitHub functionality. That does not mean every off-platform reuse, commercial use, or public derivative is allowed under the project license.

References:

- https://docs.github.com/en/site-policy/github-terms/github-terms-of-service
- https://docs.github.com/articles/licensing-a-repository

## Contributions

Contributors should assume inbound contributions are offered under the repository's current license unless a separate written agreement says otherwise. Do not contribute material copied from third parties unless you have rights compatible with public repository hosting and TCL-ND-1.0 stewardship.

For substantial outside contributions, counsel should review:

- contributor rights and provenance
- whether a contributor license agreement is needed
- whether TCL-ND-1.0 is still the intended public posture
- how NoDerivatives interacts with public pull requests, forks, translations, mirrors, and educational reuse

## Current Release Rule

License clarity is a release gate. Public pages, README text, package metadata, and contributor guidance should avoid language that promises open-source freedoms the license does not grant.

# Map Pin — Join Flow

## Purpose (why)
Let a new supporter add their location pin to the living map in under 60 seconds.

## User Story
As a visitor, I want to add my pin and a short note, so that I feel connected and counted in the network.

## Inputs
- Button: "Add my pin"
- Fields: name (optional), city/country (required), short note (optional)

## Outputs
- New pin appears on the map
- Confirmation toast: "You’re in the weave!"

## Acceptance Criteria (checkable)
- [ ] Clicking "Add my pin" opens the form
- [ ] Submitting with city/country shows my pin on the map
- [ ] Error case: empty city/country shows "Please add at least your city and country"
- [ ] Works in Brave with shields up (no trackers required)

## Non-Goals
- No account system in v1
- No precise GPS required

## Notes / Examples
Example city/country: "Tel Aviv, Israel". Example note: "Met at Boka Camping."

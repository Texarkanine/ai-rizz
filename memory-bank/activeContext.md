# Active Context

## Current Task

**skill-support** — Add complete skill support to ai-rizz

## Phase

`PREFLIGHT - COMPLETE (PASS)`

## What Was Done

- Reset ai-rizz to main (stripped previous incorrect skill implementation)
- Rewrote plan with corrected two-path design:
  - `rules/<skill-name>/SKILL.md` — standalone skill (manifest entry)
  - `rulesets/<ruleset>/skills/<skill-name>/SKILL.md` — embedded in ruleset (discovered during sync)
  - NOT valid: `rulesets/skills/<name>`, `rulesets/<name>` symlink-to-skill
- Updated projectbrief.md and systemPatterns.md to reflect correct design
- Preflight passed all checks; insertion points verified against clean codebase
- Plan refinements: standalone skill check inside dir branch; embedded skills insertion point clarified

## Decisions

- Previous skill code was based on incorrect design and fully removed (git checkout main -- ai-rizz)
- Only two skill definition paths are valid (operator directive)
- Symlinks in rulesets pointing to skill dirs work via normal ruleset symlink mechanism, not special skill detection

## Next Step

Operator must run `/build` to begin implementation.

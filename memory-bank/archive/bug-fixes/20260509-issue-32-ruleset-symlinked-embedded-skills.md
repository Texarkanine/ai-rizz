---
task_id: issue-32-ruleset-symlinked-embedded-skills
complexity_level: 2
date: 2026-05-09
status: completed
---

# TASK ARCHIVE: Ruleset embedded-skill discovery for symlinked skill directories

## SUMMARY

Embedded skills under `rulesets/<ruleset>/skills/` were omitted when the entry was a symlink to an in-repository skill directory, because discovery used directory-only finds that excluded symlinked directories. Runtime discovery was updated so valid in-repo symlink targets are listed by `ai-rizz list` and deployed on install/sync, while out-of-repo symlink targets remain skipped or rejected. Integration tests, strict docs build, and documentation in `docs/rule-authoring/rulesets.md` were updated; persistent patterns were reconciled in `memory-bank/systemPatterns.md`.

## REQUIREMENTS

- Treat symlinked `skills/<name>` entries like real directories when the symlink resolves to a valid in-repo skill directory (with `SKILL.md`) for both list and install/sync.
- Preserve or strengthen symlink safety: reject or skip targets outside the repository.
- Add or adjust automated tests for in-repo support, out-of-repo rejection, and regression for normal directories and invalid entries.
- Update the documentation site to describe supported symlink behavior and constraints.

## IMPLEMENTATION

- **Runtime (`ai-rizz`):** Embedded skill discovery under each ruleset’s `skills/` directory now includes symlink entries; top-level boundary checks (`_readlink_f`, `validate_dir_symlinks`) ensure only safe in-repo targets are processed on both list and copy paths. List output skips out-of-repo symlinks without noisy errors for stability.
- **Tests:** `tests/integration/functions/test_skill_sync.test.sh` and `tests/integration/functions/test_skill_list_display.test.sh` — coverage for in-repo vs out-of-repo symlinked embedded skills and regressions for ordinary directories and non-skill entries.
- **Docs:** `docs/rule-authoring/rulesets.md` — removed obsolete “broken symlink” framing and documented current behavior and security limits.
- **Persistent memory:** `memory-bank/systemPatterns.md` — embedded-skill symlink discovery behavior recorded for future maintainers.

## TESTING

- Targeted integration suites for sync/list behavior; full `make test`; strict documentation build `make docs-build` — all passed before archive.
- Preflight and QA phases completed during the task (`memory-bank/active/.preflight-status` and `.qa-validation-status` removed at archive time as ephemeral).

## LESSONS LEARNED

The following is inlined from the final reflection (ephemeral `reflection-issue-32-ruleset-symlinked-embedded-skills.md` removed with archive).

- **Summary:** In-repo symlinked embedded skills now list and deploy correctly; out-of-repo symlinks remain rejected; requirements and docs alignment were maintained end-to-end.
- **Requirements vs outcome:** All scoped requirements were delivered; nothing was dropped or expanded beyond the agreed scope.
- **Plan accuracy:** The plan correctly identified `find`-style `-type d` discovery as the root cause in both list and copy paths.
- **Build and QA:** TDD produced a clean red/green loop; QA found no semantic rework; helper reuse kept the change small.
- **Technical:** Expanding discovery must be paired with explicit boundary validation on every newly included entry type.
- **Process:** Writing paired list and sync tests before runtime edits shortened iteration and increased confidence.
- **Deeper design note:** A single shared helper that enumerates valid `skills/` children (real dirs plus safe symlink dirs) and feeds both list and deploy would reduce long-term drift between the two code paths.

## PROCESS IMPROVEMENTS

- Continue pairing list-path and deploy-path tests when touching discovery so both user-visible and filesystem outputs stay aligned.

## TECHNICAL IMPROVEMENTS

- Optional: introduce a shared enumeration helper for valid embedded skills under `skills/` (same security checks, single definition) to prevent future list/sync divergence.

## NEXT STEPS

None required for this task. Optional shared-helper refactor is advisory only.

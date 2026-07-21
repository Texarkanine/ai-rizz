# Progress

Recommend which of the three open GitHub issues (#40, #41, #42) belong in one push, based on shared behavior and code surface.

**Complexity:** Level 1

## 2026-07-21 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Validated intent: grouping recommendation for open issues, not implementation yet
    - Classified as Level 1 (quick advisory deliverable)
* Decisions made
    - Level 1: isolated analysis answer; skip plan/creative/preflight/reflect/archive
* Insights
    - #40 and #41 both concern add-time scope selection vs global; #42 is deinit flag semantics

## 2026-07-21 - BUILD - COMPLETE

* Work completed
    - Traced #40/#41 to `select_mode()` + add path; #42 to `cmd_deinit --all`
    - Wrote grouping recommendation in tasks.md
* Decisions made
    - Bundle #40 + #41 in one push; ship #42 separately
* Insights
    - #41's "global is opt-in in repos" policy also blocks the #40 auto-select-global path; invalid-manifest write is a related defense-in-depth fix in the same surface

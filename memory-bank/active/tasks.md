# Task: M3 — wrong-level test tier (finding 16)

* Task ID: slobac-audit-fixes-2-m3
* Complexity: Level 3
* Type: refactor (test taxonomy / layout)

Re-home tests that perform real filesystem, git, and symlink integration work out of `tests/unit/` into a dedicated directory under the integration tree, then align docs and runners. Production code (`ai-rizz`) is out of scope.

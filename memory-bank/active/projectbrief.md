# Project Brief

## User Story

As a maintainer, I want a clear recommendation on which open issues belong in one push so that related scope-selection / global-mode work ships as a coherent change without mixing unrelated CLI footguns.

## Use-Case(s)

### Use-Case 1

Operator reviews [#40](https://github.com/Texarkanine/ai-rizz/issues/40), [#41](https://github.com/Texarkanine/ai-rizz/issues/41), and [#42](https://github.com/Texarkanine/ai-rizz/issues/42) and asks which subset should be one PR/push.

### Use-Case 2

Recommendation cites shared product behavior and likely code surfaces so the next `/niko` implementation run can start from a decided scope.

## Requirements

1. Evaluate all three open issues on Texarkanine/ai-rizz.
2. Recommend which issues should be tackled together in one push, and which should stay separate.
3. Ground the recommendation in how the problems relate (user-facing behavior and code surface), not only labels.

## Constraints

1. Deliverable is a grouping recommendation; no implementation in this task unless later expanded.
2. Issues: [#40](https://github.com/Texarkanine/ai-rizz/issues/40) (bug: global-only add writes invalid manifest), [#41](https://github.com/Texarkanine/ai-rizz/issues/41) (enhancement: exclude global from auto scope prompt), [#42](https://github.com/Texarkanine/ai-rizz/issues/42) (enhancement: deinit `--all` footgun / `--both`).

## Acceptance Criteria

1. Clear recommendation: which issue numbers share one push, which do not.
2. Brief rationale per grouping decision.
3. Operator can use the answer to start a follow-on implementation task without re-deriving the grouping.

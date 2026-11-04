---
name: learn-code-changes
description: Turn repository changes into plain-English, evidence-grounded learning sessions that help a user understand and remember what changed. Use when the user asks to catch up on a commit, branch, pull request, date range, worktree, or feature; wants a code-change explainer, deep dive, quiz, teach-back, or refresher; or asks for a small test-backed scenario or micro-world based on changed code.
---

# Learn Code Changes

Teach an accurate mental model of a change from the live repository; do not narrate changed lines.

## Boundary

- Read-only: inspect code, history, diffs, tests, fixtures, and supplied task or pull-request context. Do not edit files, create learning-state files, mutate a database, or start automation unless the user separately asks.
- Stateless: do not promise later review or recall.
- Plain English with exact business terms, identifiers, file names, and commands.

## Evidence

Source code is evidence of implementation, tests of expected behavior, a safe run of observed behavior; never collapse them. Label when ambiguity matters:

- **Observed:** a safe command or focused test ran in this session.
- **Expected:** an existing test or fixture specifies it; not run now.
- **Implemented:** production code contains it; runtime not observed.
- **Inferred:** reasoned interpretation, not recorded intent.
- **Unknown:** the repository does not say.

Take rationale from recorded evidence (request, task, commit or pull-request text, documentation); otherwise label it inferred or unknown. When code and tests disagree, report the conflict instead of teaching either side.

## Session

1. Use the change range the user names. If none can be identified from the request or conversation, ask one question; never default to the working tree or latest commit. State the range, distinguishing committed, staged, unstaged, and untracked work when it matters.
2. Choose the smallest mode — catch-up, deep dive, quiz or refresher, micro-world — and read its section in [session-patterns.md](references/session-patterns.md).
3. Read the repository instructions and the relevant architecture guidance before judging intent, then the owning code and representative tests. Generated files, file counts, and commit subjects are not explanations.
4. Map the change by user outcome, business rule, source of truth, or architectural decision — roughly three to seven themes — and separate behavior changes from refactors, test-only, formatting, generated, and dependency changes. Name what deliberately stayed the same when omission would mislead.
5. Explain from outcome to implementation, anchored to exact files and tight line ranges. Add implementation detail only where it explains ownership, data flow, risk, or the next decision.
6. For quizzes and teach-backs: one question per message, answer hidden until the user responds, prediction, ownership, rationale, and transfer over trivia. Accept partial answers, name the precise gap, correct with evidence, then vary the scenario once. Do not force a quiz onto an explanation request.
7. Close with the smallest durable model: the rule, any evidence conflict, the code or tests worth remembering, and one next topic.

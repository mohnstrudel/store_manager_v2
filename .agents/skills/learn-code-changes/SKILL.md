---
name: learn-code-changes
description: Turn repository changes into plain-English, evidence-grounded learning sessions that help a user understand and remember what changed. Use when the user asks to catch up on a commit, branch, pull request, date range, worktree, or feature; wants a code-change explainer, deep dive, quiz, teach-back, or refresher; or asks for a small test-backed scenario or micro-world based on changed code.
---

# Learn Code Changes

Teach from the live repository. Help the user build an accurate mental model of a change instead of narrating every changed line.

## Keep the boundary read-only

- Inspect code, history, diffs, tests, fixtures, documentation, and supplied task or pull-request context.
- Do not edit application files, create learning-state files, run migrations, mutate a database, or start an automation unless the user separately asks for that work.
- Use plain English while preserving exact business terms, identifiers, file names, and commands. Briefly explain a technical term when it affects the user's understanding.
- Treat source code as evidence of implementation, tests as evidence of expected behavior, and an actual safe run as evidence of observed behavior. Do not collapse these into one claim.
- Derive rationale from recorded evidence such as the user request, task description, commit or pull-request text, comments, or documentation. If the reason is not recorded, label it as an inference or say it is unknown.

## Select the session mode

Choose the smallest mode that satisfies the request:

- **Catch-up:** Group a change range into a short map of important business and architecture changes.
- **Deep dive:** Explain one behavior or decision from user outcome through its owning code and tests.
- **Quiz or refresher:** Use active recall to check an existing mental model before explaining again.
- **Micro-world:** Turn a difficult state transition, allocation, integration, or multi-step flow into a small scenario grounded in existing code and tests.

Read [session-patterns.md](references/session-patterns.md) after selecting a mode. Use only the relevant section unless the user combines modes.

## Follow the core workflow

### 1. Set the change range

Use an explicit commit, branch comparison, date range, worktree scope, feature, task, or pull request when the user supplies one.

If the range is absent and cannot be identified from the user's wording or current conversation, ask one focused question before teaching. Do not silently choose the working tree, latest commit, or an arbitrary recent period.

State the chosen range at the start of the lesson. Distinguish committed, staged, unstaged, and untracked changes when that difference matters.

### 2. Inspect the repository evidence

Read the repository instructions and the relevant architecture or domain guidance before judging intent. Then inspect the smallest useful set of:

- commit history and change descriptions;
- changed and surrounding production code;
- tests and fixtures that describe affected behavior;
- routes, schemas, generated contracts, or integration payloads when relevant; and
- task, pull-request, or user context that records the reason for the change.

Do not treat generated files, file counts, or commit subjects as sufficient explanations. Check the owning code and representative tests. Include untracked files when the scope is the current worktree.

### 3. Build a change map

Cluster changes by user outcome, business rule, source of truth, or architectural decision rather than by directory. Keep the first pass to roughly three to seven themes. If the range is larger, prioritize the important themes and say what remains outside the first pass.

For each material theme, determine:

- what happened before and what happens now;
- why the change was made, or whether the reason is only inferred;
- who or what is affected;
- which object or component owns the rule now;
- important edge cases, risks, or boundaries; and
- what deliberately stayed the same when that prevents a wrong conclusion.

Separate behavior changes from refactors, test-only changes, formatting, generated output, and dependency maintenance.

### 4. Explain from outcome to implementation

Lead with the result in business language. Add implementation detail only when it explains ownership, data flow, risk, or the next decision.

Link claims to exact repository files and tight line anchors when useful. Use a small table or flow only when it makes several relationships easier to understand. Avoid line-by-line narration unless the user asks for it.

Use these evidence labels in prose when ambiguity matters:

- **Observed:** A safe command or focused test was actually run in this session.
- **Expected:** An existing test or fixture specifies the behavior, but it was not run now.
- **Implemented:** Production code contains the behavior, but runtime behavior was not observed now.
- **Inferred:** The explanation is a reasoned interpretation rather than recorded intent.
- **Unknown:** The repository does not provide enough evidence.

If production code and tests disagree, report the conflict. Do not teach either side as settled behavior.

### 5. Make understanding active

When the user requests a quiz, refresher, teach-back, or combined learning session:

- Ask one question at a time and wait for the answer.
- Do not include the answer or a strong hint in the same message unless the user asks to reveal it.
- Prefer prediction, ownership, rationale, and transfer questions over syntax or vocabulary trivia.
- Accept partially correct answers, identify the precise gap, and correct it with repository evidence.
- After feedback, vary the scenario once when that checks whether the rule transfers to a new case.

Do not force a quiz when the user asked only for an explanation. End an explanation with one concise suggested next mode when active practice would help.

### 6. Close the loop

Finish with the smallest durable mental model:

- the important behavior or ownership rule;
- any uncertainty or evidence conflict;
- the exact code or tests worth remembering; and
- the next useful question or topic.

Keep the MVP stateless. Do not claim that a topic will be remembered or reviewed later unless the user separately asks for persistence or scheduling.

## Check quality before responding

- Name the exact change range.
- Group by meaning, not file layout.
- Keep facts, observed results, expected behavior, and inference distinct.
- Ground important claims in production code and representative tests.
- Use plain language without weakening technical accuracy.
- Keep quiz answers hidden until the user responds.
- Avoid repository or application mutations.

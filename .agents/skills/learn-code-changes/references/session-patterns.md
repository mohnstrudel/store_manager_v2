# Session Patterns

Use the pattern for the selected mode. Adapt the depth to the size of the change and the user's familiarity with the area.

## Catch-up

Use this mode for requests such as "catch me up," "what changed," or "explain this branch."

1. State the exact range and whether it includes committed, staged, unstaged, or untracked work.
2. Lead with the most important outcome in one or two sentences.
3. Group the range into three to seven themes, ordered by user or business importance.
4. For each theme, cover only the fields that add value:
   - **Before**
   - **Now**
   - **Why** or **Inferred reason**
   - **Why it matters**
   - **Owner or source of truth**
   - **Evidence**
5. Call out an important unchanged rule when omission would create the wrong mental model.
6. Separate behavior changes from refactors and maintenance.
7. End with the one theme most worth exploring or testing next.

For a very large range, provide a first-pass map rather than a shallow summary of every file. Name the themes not yet examined.

## Deep dive

Use this mode for one behavior, architectural decision, integration, or source-of-truth question.

1. Begin with a concrete user or business scenario.
2. Explain the previous and current behavior.
3. Trace only the meaningful path, such as request to owner to serialized response to screen.
4. Identify the authoritative model, component, or contract and explain why it owns the rule.
5. Show the representative test or fixture that specifies the expected behavior.
6. Identify edge cases and what remains unchanged.
7. End with a compact rule the user can reuse when reasoning about similar changes.

Use a flow or table only when three or more linked parts would be harder to follow in prose.

## Quiz or refresher

Start with recall. Do not repeat the explanation before the first question unless the user asks for a hint.

Ask two to four questions, one at a time, chosen from different levels:

- **Outcome:** What user-visible or business behavior changed?
- **Prediction:** Given a concrete input or state, what happens next?
- **Ownership:** Which model or component owns the rule, and why?
- **Rationale:** What problem or constraint led to the design?
- **Transfer:** How would the rule apply to a different but related case?
- **Boundary:** What did not change, or which tempting conclusion would be wrong?

Avoid trick questions, obscure line numbers, syntax recall, and unexplained jargon. Use plausible wrong options only when multiple choice materially lowers the effort of answering.

After each answer:

1. Say what was correct.
2. Name the smallest missing or incorrect part.
3. Give the corrected model in plain English.
4. Point to exact production and test evidence.
5. Ask the next question or one varied transfer question.

At the end, summarize only the concepts that were missed or remained uncertain.

## Test-backed micro-world

Use this mode only when interaction will clarify a difficult rule better than another explanation.

### Prepare

1. Select one existing test or fixture that represents the changed behavior.
2. Check the corresponding production code rather than trusting the test alone.
3. Reduce the setup to the few states and values needed for the rule.
4. Keep exact domain terms, but remove incidental framework detail.
5. If the test and production code disagree, stop and explain the conflict.

### Run the learning interaction

1. Present the initial state.
2. Present one action or changed input.
3. Ask the user to predict the outcome and explain why.
4. Wait for the answer.
5. Reveal the outcome with the correct evidence label:
   - say **Expected by the test** when the scenario was read but not executed;
   - say **Implemented in the code** for a static code conclusion;
   - say **Observed in this session** only after a safe run actually produced the result.
6. Change one condition and ask a transfer question if it tests the same rule without adding noise.

Do not invent runtime evidence. Illustrative values are acceptable when labeled and when the result follows unambiguously from checked code or a test fixture.

## Evidence anchors

Prefer anchors that explain meaning:

1. owning production model or component;
2. representative behavior test;
3. route, schema, serializer, or integration contract when relevant;
4. user request, task, commit, or pull-request text for rationale; and
5. generated output only as confirmation of a contract already found elsewhere.

Use exact file paths and tight line references. Do not bury the lesson under a long source list.

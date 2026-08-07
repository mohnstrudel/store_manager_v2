# Architecture and plans

Use these rules to explain system behavior and write decision-ready plans. They guide communication, not architecture choices or a fixed plan template.

- Lead with the goal and recommended direction. Add supporting evidence and tradeoffs afterward.
- Name the model, component, or person that owns each behavior. Write `Sale allocates revenue`, not `Revenue allocation is performed`.
- Describe processes and data flow in execution order. Make each transition and behavior owner clear.
- Put the common path before exceptions, failure cases, and recovery behavior.
- Explain tradeoffs through their concrete effects on behavior, ownership, coupling, or maintenance. Avoid vague claims such as `cleaner` or `more flexible`.
- Use one main decision or action per bullet. Use a table only when it makes an exact comparison or mapping easier to see.
- Use file names and code symbols as evidence or anchors, not as a substitute for explaining behavior.
- Prefer direct verbs over noun-heavy phrases. Write `OrderImporter parses the payload`, not `Payload parsing is performed by OrderImporter`.

Include only the detail needed to make the plan safe to implement without further decisions.

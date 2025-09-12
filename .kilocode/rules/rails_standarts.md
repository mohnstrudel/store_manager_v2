Follow Ruby and Rails best practices and conventions if they can be applied. Follow SOLID, DRY, KISS, YAGNI.

Prefer having a rich domain model that captures domain vocabulary and dynamics, e.g.:

- Use domain terms.
- Model behavior not just state, e.g. objects should do things, not just hold data.
- Domain rules and constraints should be enforced within models themselves, not outside.
- Avoid Anemic Models
- Services Should Represent Domain Use Cases.
- No Technical Leakage into the Domain Layer.
- Think like a domain expert, not a programmer.
- Ask: What concepts exist in the real world? What actions happen? What rules are always true?
- Use those answers to guide class design and method behavior.

# Rails Project Configuration

## Core Principles

### Domain-Driven Design

- **Domain terminology**: Use business language in code (e.g., `PurchaseOrder`, `ship!`)
- **Encapsulate business rules**: Keep domain logic within domain objects
- **Services as use cases**: Represent business processes, not technical procedures

### Rails Conventions

- Follow RESTful patterns and Rails idioms
- Prefer Rails conventions over custom solutions when appropriate
- Keep controllers thin and delegate to services/models

### Code Quality

- Always use **RuboCop** to check code style, e.g. `rubocop path/to/file`
- Use **Strong Migrations** with `safety_assured` blocks for complex operations
- Use `bulk: true` for multiple table operations in migrations, e.g. to combine alter queries.
- Write tests that describe behavior, not implementation

### Git Workflow

- When creating commits, use descriptive commit messages that explain the "why" not just "what"
- When asked to create a commit message, just provide the message for currently staged files
- Include a brief summary line followed by bullet points for significant changes

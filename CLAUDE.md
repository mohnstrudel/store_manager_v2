# Rails Project Configuration

## Core Principles

### Domain-Driven Design

- **Domain terminology**: Use business language in code (e.g., `PurchaseOrder`, `ship!`)
- **Encapsulate business rules**: Keep domain logic within domain objects
- **Services as use cases**: Represent business processes, not technical procedures

### Rails Conventions

- Follow RESTful patterns and Rails idioms
- Use `bulk: true` for multiple table operations in migrations
- Prefer Rails conventions over custom solutions when appropriate
- Keep controllers thin and delegate to services/models

### Code Quality

- **Standard** for formatting + **RuboCop** for Rails-specific rules
- Use **Strong Migrations** with `safety_assured` blocks for complex operations
- Write tests that describe behavior, not implementation

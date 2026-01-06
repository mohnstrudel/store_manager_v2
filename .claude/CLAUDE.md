# Rails Project Configuration

## Code Quality

- Always use **RuboCop** to check code style: `bundle exec rubocop path/to/file`
- Use **Strong Migrations** with `safety_assured` blocks for complex operations
- Use `bulk: true` for multiple table operations in migrations to combine alter queries
- Write tests that describe behavior, not implementation
- When creating commits, use descriptive commit messages that explain the "why" not just "what"

## Specialized Agents

This project includes specialized agents in `.claude/agents/` that encapsulate development patterns.

### Rails Development

- `rails-orchestrator-agent.md` - **Start here for any Rails development task**
- `rails-model-agent.md` - Models, concerns, POROs, state-as-records
- `rails-controller-agent.md` - Controllers, routing, concerns, authorization
- `rails-view-agent.md` - Views (Slim), caching, Turbo Streams, Stimulus

### Testing

- `rspec-rails-agent.md` - **Start here for testing** (delegates to specialized agents)
- `rspec-model-specs-agent.md` - Model specs
- `rspec-request-specs-agent.md` - Request specs
- `rspec-system-specs-agent.md` - System specs
- `rspec-activejob-specs.md` - Job specs
- `rspec-action-mailer-specs.md` - Mailer specs
- `rspec-activestorage-specs.md` - File upload specs
- `rspec-actioncable-specs.md` - WebSocket specs

## Technology Stack

- **Slim** - Templating (not ERB)
- **Tailwind CSS** - Styling with `@apply` directive (semantic classes, not utility strings in HTML)
- **Hotwire** - Turbo Streams, Turbo Frames, Stimulus
- **RSpec** - Fixtures as primary test data strategy (not factories)
- **RuboCop** - Code linting
- **Strong Migrations** - Safe database migrations

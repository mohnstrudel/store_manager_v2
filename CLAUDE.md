# Rails Project Configuration

## ⚠️ CRITICAL: BEFORE STARTING ANY TASK - MANDATORY READING

**YOU MUST READ THIS ENTIRE FILE BEFORE STARTING ANY TASK. NO EXCEPTIONS.**

### Immediate Requirements

- [ ] Read and understand this entire CLAUDE.md file
- [ ] Confirm you understand the scope and boundaries of the requested task
- [ ] Identify which sections of this file apply to your task
- [ ] Ask for clarification if ANYTHING is unclear

### Permission Boundaries

- **NEVER** create commits unless explicitly asked to "make a commit"
- **WHEN IN DOUBT, STOP AND ASK**

### Approval Workflow

1. Read CLAUDE.md completely
2. Understand the task requirements
3. Plan your approach
4. Present plan for approval
5. Wait for explicit confirmation
6. Execute approved plan only

## 📋 TASK PRE-FLIGHT CHECKLIST - MANDATORY

**Complete this checklist for EVERY task without exception:**

### Before Starting Work

- [ ] I have read the entire CLAUDE.md file
- [ ] I understand exactly what is being requested
- [ ] I have identified all relevant sections of CLAUDE.md for this task
- [ ] I understand the boundaries and limitations of this task
- [ ] I have a clear plan of action

**If you cannot check ALL boxes, STOP and ask for clarification.**

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

## 🚫 PROJECT RULES - NON-NEGOTIABLE

### ABSOLUTE PROHIBITIONS

- ❌ **NEVER** create commits unless explicitly asked to "make a commit"
- ❌ **NEVER** use git commands without permission
- ❌ **NEVER** proceed without understanding the task completely

### REQUIRED BEHAVIORS

- ✅ ALWAYS read CLAUDE.md first
- ✅ ALWAYS ask for clarification when unsure
- ✅ ALWAYS admit when you don't understand

### CONSEQUENCES

Violating these rules breaks trust and undermines the development workflow. When in doubt, STOP and ASK.

## Git Workflow

- **WARNING**: NEVER create commits unless explicitly requested
- When asked to create a commit message, just provide the message for currently staged files (DO NOT create the commit)
- When creating commits, use descriptive commit messages that explain the "why" not just "what"
- Include a brief summary line followed by bullet points for significant changes

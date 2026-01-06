---
name: commit-agent
description: Write git commits following project conventions
color: green
---

# Commit Agent

> Write git commit messages following the project's Conventional Commits style.

## Commit Message Format

This project uses **Conventional Commits** with the following format:

```
type(scope): description

[Optional detailed body with bullet points]
```

### Commit Types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring without behavior change |
| `improve` | Enhancement to existing functionality |
| `chore` | Maintenance tasks, dependencies, tooling |

### Common Scopes

- `shopify` - Shopify integration
- `woo` - WooCommerce integration
- `media` - Image/media handling
- `rubocop` - Code style fixes
- `spec` - Test changes
- `ai` - AI/agent related changes
- No scope for general changes

## Commit Message Principles

1. **Summary line** (50 chars or less):
   - Uses format `type(scope): description`
   - Starts with capital letter
   - Uses imperative mood ("Add" not "Added")
   - No period at the end

2. **Body** (optional, for significant changes):
   - Explain **why**, not just **what**
   - Use bullet points for multiple changes
   - Reference related files/classes
   - Keep lines under 72 chars when wrapping

3. **Good examples**:

```
feat(shopify): Use new Shopify API to handle images/media

- Replace ShopifyAdmin::Image with ShopifyAdmin::Media
- Update media references in controllers and views
- Add image position and alt text support
- All tests passing
```

```
refactor(media): Replace accepts_nested_attributes_for with
explicit controller coordination

- Remove accepts_nested_attributes_for :media from HasPreviewImages
- Rewrite _media_form.html.slim with manual rendering
- Update HandlesMedia concern to handle media explicitly
```

```
fix(spec): Fix errors and remove useless tests
```

## Workflow

1. **Run git status** to see staged changes:
   ```bash
   git status
   ```

2. **Run git diff --staged** to see actual changes:
   ```bash
   git diff --staged
   ```

3. **Run git log** to check recent commit style:
   ```bash
   git log --oneline -10
   ```

4. **Analyze the changes**:
   - What type of change is this? (feat/fix/refactor/improve/chore)
   - What area/scope does it affect?
   - What is the core purpose?
   - Is a detailed body needed?

5. **Draft the commit message** following the format above

6. **Create the commit**:
   ```bash
   git commit -m "type(scope): description"
   ```

   For multi-line messages, use a heredoc:
   ```bash
   git commit -m "$(cat <<'EOF'
   type(scope): description

   - Detailed point 1
   - Detailed point 2
   EOF
   )"
   ```

7. **Verify the commit**:
   ```bash
   git log -1 --format="%B"
   git status
   ```

## Determining the Type

| Scenario | Type |
|----------|------|
| Adding new functionality | `feat` |
| Fixing a bug | `fix` |
| Restructuring code, same behavior | `refactor` |
| Improving existing feature | `improve` |
| Updating dependencies, tooling | `chore` |

## Determining the Scope

Use a scope when changes are isolated to a specific area:
- `shopify` - Shopify API/integration changes
- `woo` - WooCommerce changes
- `media` - Media/image handling
- `rubocop` - Code style enforcement
- `spec` - Test-only changes
- `ai` - Agent/prompt changes

Omit scope for changes that span multiple areas or are general.

## When to Add a Body

Add a detailed body when:
- Multiple files are changed in related ways
- The change requires context or explanation
- Refactoring involves several steps
- The "why" isn't obvious from the summary

Skip the body for:
- Simple typo fixes
- Single-line changes
- Obvious bug fixes
- Test-only tweaks

## Examples by Scenario

### New Feature
```bash
feat(shopify): Add product update feature

- Implement ShopifyAdmin::Product#update
- Add ProductsController#update action
- Update form partials for edit workflow
- Add request specs for update endpoint
```

### Bug Fix
```bash
fix(woo): Handle nil address fields in customer sync

Address fields from WooCommerce API may be nil, causing
NoMethodError when calling #strip. Default to empty string.
```

### Refactoring
```bash
refactor: Replace has_many_attached_images with polymorphic Media

- Add Media model with polymorphic mediaable association
- Migrate existing product images to Media records
- Update controllers to use HandlesMedia concern
```

### Simple Fix
```bash
fix: Correct typo in sale factory description
```

## Before Creating a Commit

Checklist:
- [ ] Changes are staged (`git add`)
- [ ] Reviewed what will be committed (`git diff --staged`)
- [ ] Tests pass (`bundle exec rspec`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Commit message follows format above
- [ ] NO "Generated with..." footers or attribution text

**Important**: Never add "Generated with Claude Code", "Co-Authored-By", or any attribution footers to commit messages. Keep commits clean and focused on the change description.

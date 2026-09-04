# Ruby source-policy audit (ticket 02)

## Command

```
RUBOCOP_CACHE_ROOT=tmp/rubocop_cache mise exec -- bundle exec rubocop \
  --only Project/DepthFirstCallOrder,Project/NoProseComments \
  --format json app spec config
```

Run against the repository tree before any cleanup ticket (04-08) has touched a file.
Both cops are loaded (via `.rubocop.yml`'s `require: - ./lib/rubocop/cop/project`) but
`Enabled: false` in ordinary runs; `--only` explicitly activates them for this audit,
proving they are directly runnable independent of the global gate.

## Result

621 files inspected, 1360 offenses, exit status 1 (nonzero, as required by the Focused
verification command).

| Cop | Offenses |
| --- | --- |
| `Project/NoProseComments` | 1163 |
| `Project/DepthFirstCallOrder` | 197 |
| **Total** | **1360** |

## Offense counts by cleanup scope

| Scope | Ticket | `DepthFirstCallOrder` | `NoProseComments` | Total |
| --- | --- | --- | --- | --- |
| `app/models` | 04 | 113 | 124 | 237 |
| `app/services` | 05 | 5 | 194 | 199 |
| `app/controllers`, `app/jobs`, `app/mailers`, `app/policies` | 06 | 52 | 121 | 173 |
| `app/helpers` (see note below) | 06 | 22 | 0 | 22 |
| `spec` | 07 | 5 | 325 | 330 |
| `config` | 08 | 0 | 399 | 399 |
| **Total** | | **197** | **1163** | **1360** |

`app/channels` (`ApplicationCable::Connection`/`Channel`) produced zero offenses and needs
no cleanup ticket.

### Scope gap found during audit

Ticket 06 ("Clean remaining application Ruby") enumerates `app/controllers`, `app/jobs`,
`app/mailers`, and `app/policies`, but not `app/helpers`. `app/helpers` is
RuboCop-included (no `AllCops.Exclude` entry) and carries 22 real
`Project/DepthFirstCallOrder` offenses across 6 files. It is not a new architecture or
product decision — the Domain Contract's scope is "RuboCop-included Ruby source" with no
carve-out for helpers, and the ticket's own title ("remaining application Ruby") is the
correct bucket for it. Ticket 06's scope and acceptance criteria are updated to include
`app/helpers` so ticket 11 does not activate the gates against known, unassigned offenses.

## Representative false-positive review

Sampled 3 offenses per scope (models, services, other application Ruby, specs,
configuration) and inspected the flagged source directly:

- `app/models/sale_item/profitability.rb` — real `DepthFirstCallOrder` violations.
  `business_expenses` is called by both `realized_profit` and `expected_final_profit`;
  `realized_profit` (a root) is declared after `business_expenses` even though
  `realized_profit` must own the subtree, and `future_revenue` (an unrelated, uncalled
  root) is interleaved between `expected_final_profit` and its caller
  `profitability_status`. Hand-tracing the call graph confirms both flagged relationships;
  not a false positive.
- `app/models/concerns/variant_assignment.rb` — `validate_variant_assignment` calls
  `new_or_changed_variant_identity?`, which is declared after it; a genuine
  callee-after-caller ordering violation.
- `app/models/product/editing.rb`, `app/services/shopify/graphql/product_query.rb`,
  `app/services/shopify/api/client.rb`, `app/jobs/application_job.rb`,
  `app/controllers/concerns/media_form_handling.rb`,
  `app/jobs/shopify/create_options_and_variants_job.rb` — each flagged line is a leading
  or trailing hand-written explanatory comment (YARD-style module/method descriptions,
  narrative "why" comments), not a magic comment, tool directive, or schema block; correct
  `NoProseComments` offenses.
- `app/helpers/purchase_helper.rb`, `app/helpers/product_helper.rb` — real
  callee-before-caller violations in prop-building helper methods.
- `spec/spec_helper.rb`, `spec/features/move_purchase_items_spec.rb` — RSpec-generated
  instructional prose comments and a hand-written narrative comment; correct
  `NoProseComments` offenses.
- `config/environments/production.rb`, `config/environments/staging.rb` — Rails-generated
  template prose comments explaining each setting; correct `NoProseComments` offenses.

No false positives found in the sampled offenses. The exact-directive, magic-comment, and
schema-block allowlists were not observed suppressing any real prose in the sample, and no
ignored-dispatch call site (macros, `super`, other receivers, `send`, aliases, generated
accessors) was seen creating a spurious ordering edge.

## Scope not audited here

No legacy prose comment was removed and no method was reordered by this ticket. Cleanup
happens in tickets 04-10; ticket 11 activates the gates globally once all scopes are clean.

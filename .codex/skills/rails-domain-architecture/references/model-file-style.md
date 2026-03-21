# Model File Style

## Goal

Keep model files readable at a glance. The file should tell a future reader:

1. what the model is made of,
2. which behaviors it owns,
3. which behaviors are shared, and
4. where the public entry points live.

This is a style guide for Rails models and model-adjacent POROs, not generic Ruby classes.

## Preferred Shape For Base Models

Use the base model as a composition root. Keep it short and regular.

Recommended order:

1. `# frozen_string_literal: true`
2. schema comment
3. class declaration
4. `include` / `extend` lines
5. class-level configuration macros
6. validations
7. associations
8. rich text, attachments, nested attributes, enums, and other schema-backed declarations
9. named scopes
10. callbacks
11. public class methods
12. public instance methods
13. private helpers

Use blank lines to separate distinct groups when the file would otherwise feel dense.

Example:

```ruby
class Product < ApplicationRecord
  include HasAuditNotifications
  include HasPreviewImages
  include Listing
  include Searchable
  include Shopable
  include Titling

  extend FriendlyId

  audited associated_with: :franchise
  has_associated_audits
  friendly_id :find_slug_candidate, use: :slugged
  paginates_per 50

  validates :title, presence: true
  validates :sku, presence: true
  validates_db_uniqueness_of :sku

  db_belongs_to :franchise, inverse_of: :products
  db_belongs_to :shape, inverse_of: :products
  has_many :editions, dependent: :destroy, autosave: true, inverse_of: :product

  has_rich_text :description
  accepts_nested_attributes_for :purchases

  after_create :update_full_title

  def self.woo_id_is_valid?(woo_id)
    !woo_id.in? [0, "0", ""]
  end

  def created_at_for_display
    woo_created_at || created_at
  end
end
```

## Rails-Specific Rules

- Prefer `include` lines for capability modules at the top of the class.
- Keep `extend` lines near the other top-level class configuration.
- Keep broad model setup in the base file; move business behavior into `app/models/<model>/<capability>.rb`.
- Keep scopes close to the associations or data they depend on.
- Keep callbacks near the rest of the model wiring, before method bodies.
- Keep public instance methods below macros so the file reads top-down from structure into behavior.
- Keep private helpers at the bottom.
- Put `belongs_to` / `db_belongs_to` declarations in their own association block, then leave a blank line before `has_many` / `has_one` collections when that separation improves scanability.
- Group macros by purpose instead of flattening all declarations into one block.
- Typical macro groups are:
  - audit and persistence wrappers such as `audited` and `has_associated_audits`
  - behavior wiring such as `broadcasts_refreshes`
  - model identity and pagination such as `friendly_id` and `paginates_per`
  - read-shape or search definitions such as `set_search_scope`
- If a macro group gets visually heavy, split it with a blank line even if the declarations all technically belong to the same model setup section.

## Methods And Class APIs

- Prefer `def self.some_method` for a small number of class-level helpers.
- Use `class_methods do` in concerns when the class API belongs to a reusable module.
- Avoid `class << self` in models unless there is a clear benefit.
- Avoid overriding `initialize` on Active Record models.
- Use alias methods sparingly. If they exist for compatibility, put them at the end of the public API section.

## What Usually Should Not Appear In A Base Model

- explicit `require` calls for code that Zeitwerk already autoloads
- constructors
- long orchestration logic
- query wrappers that only duplicate a single scope or preload set
- presentation-only string formatting that belongs in a capability module or helper

## Concern And Capability File Style

For `app/models/<model>/<capability>.rb`:

1. `include`/`extend` lines
2. `included do` for macros and callbacks only
3. public instance methods
4. private helpers

Keep `included` blocks focused on wiring. Do not hide ordinary instance methods inside `included`.

## Practical Check

If a model file is hard to scan, ask:

- Can this become a capability module?
- Can this be a named scope?
- Can this be a callback or validation near the owning model?
- Can the public API be reduced to a few obvious methods?

If yes, move it and keep the base file simpler.

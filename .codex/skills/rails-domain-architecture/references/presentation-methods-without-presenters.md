# Presentation Methods Without Presenters

Use this guide when a Rails codebase has many “presentational” methods on models but you do not want to introduce a blanket presenter layer.

## Core Read

- Do not add presenters by default.
- First classify each method by what it is actually for.
- In model-centric Rails apps, “presentation-like” methods usually belong in one of four places:
- helpers and views
- explicit edge templates such as Jbuilder or Turbo Stream
- model-adjacent domain representation objects
- the model itself, but only when the text is part of the domain API

## 1. The Sorting Rule

Ask of each method:

1. Is this for one screen, one widget, one dropdown, or one response format?
2. Is this reused across exports, mailers, notifications, jobs, search, or integrations?
3. Is this business language, or just UI wording and formatting?
4. Does it include routes, HTML, CSS classes, or view-only decoration?

Default placement:
- one-screen or one-format method -> helper, partial, Jbuilder, Turbo template
- reusable domain representation -> model-adjacent object under `app/models/<namespace>/`
- pure business state or identity text -> model or capability module

## 2. What Usually Moves Out Of Models

- `*_for_select`
- `summary_for_<screen>`
- button labels
- route-linked snippets
- HTML builders
- CSS class helpers
- text that only exists for one form, index table, or detail page

Good target files:
- `app/helpers/<resource>_helper.rb`
- `app/views/<resource>/_row.html.erb`
- `app/views/<resource>/_option.html.erb`
- `app/views/<resource>/show.json.jbuilder`

## 3. What Can Stay On The Model

- names that are part of the domain itself
- concise business labels reused in many places
- status names and state predicates
- titles that identify the record across jobs, mailers, exports, and admin flows

Examples that may stay:
- `full_title`
- `title` when it is a true record identity
- `active?`
- `completed?`
- `base_model?`

If a formatting method is reused across parsers, jobs, imports, sync flows, and only incidentally appears in views, treat it as a domain representation and keep it near the model.

## 4. What Should Become Model-Adjacent Representation Objects

- payload text reused across channels
- export-specific labels
- notification text
- AI prompt text
- event descriptions
- integration-specific representations

Good target files:
- `app/models/<resource>/description.rb`
- `app/models/<resource>/payload.rb`
- `app/models/<resource>/exportable.rb`
- `app/models/<resource>/promptable.rb`

## 5. How To Read Legacy Commerce Methods

Typical legacy examples:
- `select_title`
- `build_title_for_select`
- `summary_for_warehouse`
- `which_edition`
- `name_and_email`
- `build_full_title_with_shop_id`

How to classify them:
- if it is only for dropdowns or forms, move to helpers
- if it is only for one warehouse screen, move to a helper or partial
- if it is a durable domain identity reused across processes, keep it near the model
- if it is for external store integration, consider a model-area representation object

## 5.5. Stable Title Builders

- A method like `generate_full_title` is often not presenter logic at all.
- If it defines the durable identity text of the record and is reused by parsers, jobs, sync code, imports, or admin flows, keep it near the model.
- The preferred refactor is usually:
- move from `self.generate_full_title(product)` to an instance-oriented API
- place it in `app/models/product/titling.rb`
- keep the base model free of formatting clutter by including the capability module

Prefer:

```ruby
module Product::Titling
  extend ActiveSupport::Concern

  def full_title_text
    [base_title_part, brand_title_part].compact_blank.join(" | ")
  end

  private
    def base_title_part
      return title if title == franchise.title

      "#{franchise.title} — #{title}"
    end

    def brand_title_part
      titles = brands.loaded? ? brands.map(&:title) : brands.pluck(:title)
      titles.compact_blank.join(", ").presence
    end
end
```

Avoid:
- helper extraction when the method is used mostly outside views
- presenter extraction just because the return value is a string
- class methods that take an instance of the same model unless there is a strong reason

## 6. Suggested Refactor Targets For Legacy Apps

From model methods to helpers:
- `app/helpers/products_helper.rb`
- `app/helpers/sales_helper.rb`
- `app/helpers/purchases_helper.rb`
- `app/helpers/customers_helper.rb`

From model methods to model-area objects:
- `app/models/sale/summary.rb`
- `app/models/purchase/summary.rb`
- `app/models/customer/identity_label.rb`
- `app/models/product/store_reference.rb`

## 7. What Not To Do

- Do not introduce a generic `ProductPresenter` or `SalePresenter` just because the model has text helpers.
- Do not leave screen-only formatting on the model “for reuse” when the reuse is only across templates.
- Do not move true domain representations into helpers.

## 8. Anti-Default LLM Checklist

- Do not answer “use presenters” as the default fix.
- Do not keep every legacy text method on the model just because it returns a string.
- Do not move all string-building out of the model without distinguishing domain identity from screen formatting.
- Do not move stable cross-process title builders to helpers just because they are also rendered in views.

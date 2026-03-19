# Store Manager V2

Rails app with Slim views, Tailwind CSS, Turbo responses, RSpec, and Shopify sync.

## Repo-specific notes

- `Current` is intentionally small in [app/models/current.rb](/Users/geny/Developer/store_manager_v2/app/models/current.rb): it stores `session` and delegates `user`. Do not assume a broader request context.
- Follow the existing Slim + Turbo patterns in [app/views](/Users/geny/Developer/store_manager_v2/app/views).
- If view code is mostly Ruby and very little markup, move that logic into a helper or model-facing presenter method.
- Tailwind styles are centralized under [app/assets/tailwind/application.css](/Users/geny/Developer/store_manager_v2/app/assets/tailwind/application.css) and related files. Prefer extending those over long inline utility strings.
- RSpec already mixes fixtures and `FactoryBot` in [spec/rails_helper.rb](/Users/geny/Developer/store_manager_v2/spec/rails_helper.rb). Reuse the nearest pattern and avoid churn in spec helpers.
- Route Shopify Admin GraphQL work through [app/services/shopify/api/client.rb](/Users/geny/Developer/store_manager_v2/app/services/shopify/api/client.rb) and the query/mutation objects under [app/services/shopify/graphql](/Users/geny/Developer/store_manager_v2/app/services/shopify/graphql).

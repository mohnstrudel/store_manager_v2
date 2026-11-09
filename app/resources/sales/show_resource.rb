# frozen_string_literal: true

class Sales::ShowResource < Sales::TaggingPageResource
  typelize "SalesDetail"
  attribute :sale do |page|
    Sales::DetailResource.new(page.fetch(:sale), params: {can_view_profitability: page.fetch(:can_view_profitability)}).serializable_hash
  end
end

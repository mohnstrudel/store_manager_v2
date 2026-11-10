# frozen_string_literal: true

class Sales::IndexResource < Sales::TaggingPageResource
  typelize "Array<SalesListing>"
  attribute :sales do |page|
    Sales::ListingResource.new(page.fetch(:sales)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:sales))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:criteria)[:query]}
  end

  typelize '"newest" | "oldest"'
  attribute :sort do |page|
    page.fetch(:criteria)[:sort]
  end

  typelize({hide_partial_payments: :boolean, missing_purchases_only: :boolean, tag_id: "number | null"})
  attribute :filters do |page|
    page.fetch(:criteria).slice(:hide_partial_payments, :missing_purchases_only, :tag_id)
  end

  typelize :boolean
  attribute :can_view_broken_sales do |page|
    page.fetch(:can_view_broken_sales)
  end

  typelize :number, nullable: true
  attribute :broken_problem_count do |page|
    page.fetch(:broken_problem_count)
  end

  typelize :string, nullable: true
  attribute :last_sync_at do |_page|
    format_last_fetched_at(Config.shopify_sales_sync_at)
  end

  typelize :string, nullable: true
  attribute :last_sync_time do |_page|
    Config.shopify_sales_sync_time
  end
end

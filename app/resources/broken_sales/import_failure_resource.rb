# frozen_string_literal: true

class BrokenSales::ImportFailureResource < BrokenSales::IssueResource
  typelize '"import_failure"'
  attribute :kind do |_failure|
    "import_failure"
  end

  typelize '"shopify" | "woo"'
  attribute :store_type, &:store_name

  typelize :string
  attribute :order_title do |failure|
    failure.sale&.shop_identifier.presence || failure.store_order_number
  end

  typelize :string, nullable: true
  attribute :record_path do |failure|
    failure.sale && sale_path(failure.sale)
  end

  typelize :string
  attribute :message, &:message

  typelize :string
  attribute :first_failed_at do |failure|
    format_datetime(failure.first_failed_at)
  end

  typelize :string
  attribute :last_failed_at do |failure|
    format_datetime(failure.last_failed_at)
  end

  typelize :number
  attribute :failure_count, &:failure_count

  typelize :string
  attribute :pull_path do |failure|
    import_failure_pull_path(failure)
  end

  typelize :string, nullable: true
  attribute :sentry_url do |failure|
    sentry_event_url(failure.sentry_event_id)
  end
end

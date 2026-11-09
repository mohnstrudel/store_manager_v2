# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrokenSales::ImportFailureResource do
  def serialize(failure)
    described_class.new(failure).serializable_hash.deep_symbolize_keys
  end

  def record_failure(store_name:, store_order_id:, sentry_event_id:)
    Sale::ImportFailure.record(store_name:, store_order_id:, message: "Import failed", sentry_event_id:, failed_at: Time.current)
    Sale::ImportFailure.find_by!(store_name:, store_order_id:)
  end

  it "links the Sentry event and pulls a failure without a Sale by its store order id" do
    failure = record_failure(store_name: "shopify", store_order_id: "gid://shopify/Order/5150", sentry_event_id: "feb437a242d04aad8ca03229fd7bcb5a")

    expect(serialize(failure)).to include(
      store_type: "shopify",
      order_title: "5150",
      record_path: nil,
      failure_count: 1,
      pull_path: "/broken_sales/import_failures/#{failure.id}/pull",
      sentry_url: "https://handsomecake-goodies.sentry.io/issues/?query=feb437a242d04aad8ca03229fd7bcb5a"
    )
  end

  it "omits the Sentry link without an event id" do
    failure = record_failure(store_name: "woo", store_order_id: "77", sentry_event_id: nil)

    expect(serialize(failure)).to include(order_title: "77", sentry_url: nil)
  end
end

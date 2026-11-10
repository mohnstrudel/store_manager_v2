# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrokenSales::Counts do
  subject(:counts) { described_class.new(integrity:) }

  let(:integrity) do
    instance_double(
      Variant::AssignmentIntegrity,
      counts: {sale_items: 81, purchases: 44, purchase_item_links: 0, sku_collisions: 96, shopify_conflicts: 1}
    )
  end

  before do
    3.times do |index|
      Sale::ImportFailure.record(
        store_name: "woo", store_order_id: "failed-#{index}", message: "Woo order failed",
        sentry_event_id: nil, failed_at: Time.current
      )
    end
    Sale::ImportFailure.resolve(store_name: "woo", store_order_id: "failed-2")
    Sale::ImportFailure.record(
      store_name: "woo", store_order_id: "failed-3", message: "Woo order failed", sentry_event_id: nil, failed_at: Time.current
    )
  end

  it "adds unresolved import failures to the integrity tab counts" do
    expect(counts.by_tab).to eq(
      sale_items: 81, purchases: 44, purchase_item_links: 0, sku_collisions: 96, shopify_conflicts: 1, import_failures: 3
    )
  end

  it "totals every tab" do
    expect(counts.total).to eq(225)
  end
end

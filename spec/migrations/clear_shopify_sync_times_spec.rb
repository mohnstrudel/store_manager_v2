# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261109220500_clear_shopify_sync_times")

RSpec.describe ClearShopifySyncTimes do
  def run_up
    migration = described_class.new
    migration.suppress_messages { migration.migrate(:up) }
  end

  it "clears both Shopify sync times, which were stamped at click time and cannot be trusted" do
    Config.update_shopify_products_sync_time(Time.utc(2026, 11, 9, 10))
    Config.update_shopify_sales_sync_time(Time.utc(2026, 11, 9, 11))

    run_up

    expect(Config.shopify_products_sync_at).to be_nil
    expect(Config.shopify_sales_sync_at).to be_nil
  end

  it "keeps the other settings" do
    Config.enable_sales_hook

    run_up

    expect(Config.sales_hook_disabled?).to be(false)
  end
end

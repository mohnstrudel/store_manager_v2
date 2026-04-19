# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductHelper do
  describe "#product_timestamp_columns" do
    it "returns the local timestamp first and only includes populated store timestamps" do
      product = create(:product)
      product.woo_info.destroy!
      product.update_columns( # rubocop:disable Rails/SkipsModelValidations
        created_at: Time.zone.parse("2026-04-19 09:00"),
        updated_at: Time.zone.parse("2026-04-21 14:00")
      )
      product.shopify_info.update!(
        ext_created_at: Time.zone.parse("2026-04-20 10:00"),
        ext_updated_at: Time.zone.parse("2026-04-22 11:00")
      )

      created_columns = helper.product_timestamp_columns(product, :created_at)
      updated_columns = helper.product_timestamp_columns(product, :updated_at)

      aggregate_failures do
        expect(created_columns.map { |column| column[:key] }).to eq(%w[created shopify])
        expect(created_columns.map { |column| column[:label] }).to eq(["StoreMate", "Shopify"])
        expect(created_columns.map { |column| column[:value].to_date }).to eq(
          [Date.new(2026, 4, 19), Date.new(2026, 4, 20)]
        )

        expect(updated_columns.map { |column| column[:key] }).to eq(%w[updated shopify])
        expect(updated_columns.map { |column| column[:label] }).to eq(["StoreMate", "Shopify"])
        expect(updated_columns.map { |column| column[:value].to_date }).to eq(
          [Date.new(2026, 4, 21), Date.new(2026, 4, 22)]
        )
      end
    end
  end
end

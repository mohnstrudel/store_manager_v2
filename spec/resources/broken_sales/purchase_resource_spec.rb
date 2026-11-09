# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrokenSales::PurchaseResource do
  it "labels deactivated real Variants as historical and leaves active ones plain" do
    product = create(:product)
    active_variant = create(:variant, :with_version, product:, version_value: "Active")
    historical_variant = create(:variant, :with_color, product:, color_value: "Archive")
    purchase = create(:purchase, product:, variant: historical_variant)
    historical_variant.update!(deactivated_at: Time.current)

    issue = described_class.new(purchase.reload, params: {reasons: {purchase.id => "product_mismatch"}}).serializable_hash.deep_symbolize_keys

    expect(issue[:current_variant_label]).to eq("#{historical_variant.title} (Historical)")
    expect(issue[:candidates]).to contain_exactly(
      {value: active_variant.id, label: active_variant.title, base_model: false},
      {value: historical_variant.id, label: "#{historical_variant.title} (Historical)", base_model: false}
    )
  end

  it "names a missing Variant" do
    purchase = create(:purchase)
    purchase.update_columns(variant_id: nil) # rubocop:disable Rails/SkipsModelValidations

    issue = described_class.new(purchase.reload, params: {reasons: {}}).serializable_hash.deep_symbolize_keys

    expect(issue[:current_variant_label]).to eq("Missing Variant")
  end
end

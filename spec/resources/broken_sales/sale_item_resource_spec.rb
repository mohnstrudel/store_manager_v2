# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrokenSales::SaleItemResource do
  let(:product) { create(:product, title: "Revealing Armor") }
  let!(:red) { create(:variant, :with_color, product:, color_value: "Red") }
  let(:customer) { create(:customer, first_name: "Anna", last_name: "Müller") }

  def order_line(status: "processing", qty: 2, linked: 0, variant: nil)
    sale = create(:sale, status:, customer:)
    create(:sale_item, sale:, product:, variant: red).tap do |line|
      line.update_columns(variant_id: variant&.id, qty:, purchase_items_count: linked)
    end
  end

  def consequences(line, reason: "missing_variant", import_failure: nil)
    described_class.new(
      SaleItem.preload(sale: :customer, variant: :product, product: :variants).find(line.id),
      params: {
        reasons: {line.id => reason},
        impact: Variant::AssignmentImpact.new(integrity: Variant::AssignmentIntegrity.new),
        import_failures_by_sale_id: {line.sale_id => import_failure}.compact
      }
    ).serializable_hash.deep_symbolize_keys.fetch(:consequences)
  end

  it "names the unreserved units, the customer, and the Product for an active unlinked line" do
    expect(consequences(order_line)).to eq([
      {kind: "units_not_reserved", text: "2 units for Anna Müller aren't reserved. They may not arrive on time."},
      {kind: "debt_miscounted", text: "#{product.full_title} may be under-ordered: this sale isn't counted in what we owe."},
      {kind: "variant_not_recorded", text: "History doesn't record which Variant Anna Müller bought."}
    ])
  end

  it "uses the singular for one unreserved unit" do
    expect(consequences(order_line(qty: 1)).first).to eq(
      kind: "units_not_reserved", text: "1 unit for Anna Müller isn't reserved. It may not arrive on time."
    )
  end

  it "names the line's Variant in the debt consequence when it is known" do
    other_product = create(:product)
    foreign = create(:variant, :with_color, product: other_product, color_value: "Blue")

    expect(consequences(order_line(linked: 2, variant: foreign), reason: "product_mismatch")).to eq([
      {kind: "debt_miscounted", text: "#{other_product.full_title} → #{foreign.title} may be under-ordered: this sale isn't counted in what we owe."},
      {kind: "wrong_variant_recorded", text: "History records the wrong Variant for Anna Müller."}
    ])
  end

  it "names the store and the date the order stopped updating" do
    line = order_line(linked: 2)
    failure = Sale::ImportFailure.create!(
      store_name: "woo",
      store_order_id: "4242",
      sale: line.sale,
      message: "Import failed",
      first_failed_at: Time.zone.local(2026, 11, 9, 14, 5),
      last_failed_at: Time.zone.local(2026, 11, 10, 8, 0)
    )

    expect(consequences(line, import_failure: failure).last).to eq(
      kind: "not_updating", text: "Not updating from Woo since 9.\u00A0Nov\u00A0’26: status and payments here may be out of date."
    )
  end

  it "says history doesn't record the Variant for a closed order" do
    expect(consequences(order_line(status: "cancelled"))).to eq([
      {kind: "variant_not_recorded", text: "History doesn't record which Variant Anna Müller bought."}
    ])
  end

  it "says history records the wrong Variant for a completed order" do
    foreign = create(:variant, :with_color, product: create(:product), color_value: "Blue")

    expect(consequences(order_line(status: "completed", variant: foreign), reason: "product_mismatch")).to eq([
      {kind: "wrong_variant_recorded", text: "History records the wrong Variant for Anna Müller."}
    ])
  end

  it "refers to the customer generically when the customer has no name" do
    customer.update!(first_name: nil, last_name: nil)

    expect(consequences(order_line(status: "cancelled"))).to eq([
      {kind: "variant_not_recorded", text: "History doesn't record which Variant this customer bought."}
    ])
  end
end

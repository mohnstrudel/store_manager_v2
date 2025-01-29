require "rails_helper"

describe ProductMover do
  let(:purchase) { create(:purchase, amount: 2) }
  let(:from_warehouse) { create(:warehouse) }
  let(:to_warehouse) { create(:warehouse) }
  let(:purchased_products) {
    create_list(:purchased_product, 3, warehouse: from_warehouse, purchase:)
  }

  it "moves all products to the destination warehouse" do
    moved_count = described_class.new(
      warehouse_id: to_warehouse.id,
      purchased_products_ids: purchased_products.map(&:id)
    ).move

    expect(moved_count).to eq(3)

    purchased_products.each do |product|
      expect(product.reload.warehouse_id).to eq(to_warehouse.id)
    end
  end

  it "returns 0 and doesn't dispatch notifications when no products are moved" do
    moved_count = described_class.new(
      warehouse_id: to_warehouse.id
    ).move

    expect(moved_count).to eq(0)
  end
end

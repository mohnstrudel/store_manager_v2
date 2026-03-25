# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::FormRehydrator do
  subject(:rehydrated_product) { described_class.new(product:, payload:).call }

  let(:product) { create(:product, title: "Original Title", sku: "SKU-1") }
  let!(:edition) do
    create(
      :edition,
      product:,
      sku: "OLD-ED",
      size: create(:size, value: "1/4"),
      version: create(:version, value: "Regular"),
      color: create(:color, value: "Blue")
    )
  end
  let(:store_info) { product.store_infos.woo.first }
  let(:payload) do
    Product::FormPayload.new(params: ActionController::Parameters.new(
      product: {
        title: "Updated Title",
        sku: product.sku,
        franchise_id: product.franchise_id.to_s,
        shape_id: product.shape_id.to_s,
        brand_ids: [],
        color_ids: [],
        size_ids: [],
        version_ids: []
      },
      store_infos: {
        "0" => {
          id: store_info.id.to_s,
          tag_list: "new-tag",
          store_name: "woo",
          _destroy: "0"
        }
      },
      editions: {
        "0" => {
          id: edition.id.to_s,
          sku: "UPDATED-ED",
          size_id: edition.size_id.to_s,
          version_id: edition.version_id.to_s,
          color_id: edition.color_id.to_s,
          purchase_cost: "10",
          selling_price: "20",
          weight: "1"
        },
        "1" => {
          sku: "NEW-ED",
          size_id: create(:size, value: "1/6").id.to_s,
          version_id: create(:version, value: "Special").id.to_s,
          color_id: create(:color, value: "Red").id.to_s,
          purchase_cost: "15",
          selling_price: "25",
          weight: "2"
        }
      }
    ))
  end

  before do
    store_info.update!(tag_list: "old-tag")
    product.errors.add(:title, "can't be blank")
  end

  it "rebuilds unsaved form state on a fresh product instance" do # rubocop:disable RSpec/MultipleExpectations
    expect(rehydrated_product).not_to be(product)
    expect(rehydrated_product.title).to eq("Updated Title")
    expect(rehydrated_product.errors[:title]).to include("can't be blank")
    expect(rehydrated_product.store_infos.find { |item| item.id == store_info.id }.tag_list).to eq(["new-tag"])
    expect(rehydrated_product.editions.find { |item| item.id == edition.id }.sku).to eq("UPDATED-ED")

    new_edition = rehydrated_product.editions.find { |item| item.new_record? }
    expect(new_edition.sku).to eq("NEW-ED")
    expect(new_edition.instance_variable_get(:@_new_edition_index)).to eq(1)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /purchases/product_variants" do
  before { sign_in_as_admin }

  it "returns variants for the given product in value/label format" do
    product = create(:product)
    variant = create(:variant, product:)

    get product_variants_path, params: {product_id: product.id}, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["variants"]).to include(
      {"value" => variant.id, "label" => variant.title}
    )
  end

  it "only returns variants for the specified product" do
    product = create(:product)
    other_variant = create(:variant, product: create(:product))

    get product_variants_path, params: {product_id: product.id}, as: :json

    returned_ids = response.parsed_body["variants"].map { _1["value"] }
    expect(returned_ids).not_to include(other_variant.id)
  end
end

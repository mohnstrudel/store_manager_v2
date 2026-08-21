# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /products/:product_id/assignable_variants" do
  let(:request_path) { "/products/#{product.id}/assignable_variants" }
  let(:product) { create(:product) }

  after { log_out }

  it "returns fixed Base mode from the authorized Product" do
    sign_in_as_admin

    get request_path, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "mode" => "base",
      "variants" => [
        {
          "value" => product.base_variant.id,
          "label" => "Base Model",
          "base_model" => true
        }
      ]
    )
  end

  it "returns active real Variants in select mode without another Product's Variants" do
    sign_in_as_admin
    active_variant = create(:variant, product:, size: create(:size, value: "Large"))
    deactivated_variant = create(:variant, product:, size: create(:size, value: "Small"))
    deactivated_variant.update!(deactivated_at: Time.current)
    other_variant = create(:variant, product: create(:product), size: create(:size, value: "Other"))

    get request_path, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "mode" => "select",
      "variants" => [
        {
          "value" => active_variant.id,
          "label" => active_variant.title,
          "base_model" => false
        }
      ]
    )
    expect(response.parsed_body.dig("variants", 0, "value")).not_to eq(other_variant.id)
  end

  it "allows a manager who can read the Product" do
    sign_in create(:user, :manager)

    get request_path, as: :json

    expect(response).to have_http_status(:ok)
  end

  it "rejects support users who cannot read the Product" do
    sign_in create(:user, :support)

    get request_path, as: :json

    expect(response).to redirect_to(noop_path)
  end
end

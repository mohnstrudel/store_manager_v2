# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Prosopite request scanning" do
  it "scans GET and HEAD requests" do
    expect(Prosopite).to receive(:scan).twice.and_call_original

    get sign_in_path
    head sign_in_path

    expect(response).to have_http_status(:ok)
  end

  it "does not scan write requests" do
    expect(Prosopite).not_to receive(:scan)

    post session_path, params: {email_address: "bad@example.com", password: "wrong"}

    expect(response).to redirect_to(sign_in_path)
  end

  it "does not scan PATCH or DELETE requests" do
    sign_in_as_admin
    product = create(:product)
    expect(Prosopite).not_to receive(:scan)

    patch product_path(product), params: {
      product: {title: product.title, franchise_id: product.franchise_id, shape: product.shape}
    }
    delete product_path(product)

    expect(response).to redirect_to(products_path)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inertia show pages" do
  before { sign_in_as_admin }

  it "renders purchase item show" do
    purchase_item = create(:purchase_item)

    get purchase_item_path(purchase_item)

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("PurchaseItems/Show")
    expect(inertia.props[:purchase_item][:id]).to eq(purchase_item.id)
  end

  it "renders sale item show" do
    sale_item = create(:sale_item)

    get sale_item_path(sale_item.sale, sale_item)

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("SaleItems/Show")
    expect(inertia.props[:sale_item][:id]).to eq(sale_item.id)
  end

  it "renders warehouse show" do
    warehouse = create(:warehouse)

    get warehouse_path(warehouse)

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("Warehouses/Show")
    expect(inertia.props[:warehouse][:id]).to eq(warehouse.id)
  end

  it "renders user show" do
    user = create(:user)

    get user_path(user)

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("Users/Show")
    expect(inertia.props[:user][:id]).to eq(user.id)
  end

  it "renders debts show" do
    get debts_path

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("Dashboard/Debts")
  end
end

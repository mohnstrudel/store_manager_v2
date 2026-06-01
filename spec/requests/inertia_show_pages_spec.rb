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

  it "includes warehouse movement history in purchase item show props" do
    first_warehouse = create(:warehouse, name: "Warehouse One")
    second_warehouse = create(:warehouse, name: "Warehouse Two")
    purchase_item = create(:purchase_item, warehouse: first_warehouse)
    purchase_item.move_to_warehouse!(second_warehouse.id)

    get purchase_item_path(purchase_item)

    movements = inertia.props[:purchase_item][:warehouse_movements]
    warehouse_names = movements.map { |m| m[:warehouse_name] }
    expect(warehouse_names).to include("Warehouse One", "Warehouse Two")
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

  it "includes purchased_amount per product in debts props" do
    product = create(:product, title: "Malenia")
    sale = create(:sale, status: "processing")
    create(:sale_item, sale:, product:, variant: nil, qty: 5)
    create(:purchase, product:, amount: 2)

    get debts_path

    debt_row = inertia.props[:debts].find { |p| p[:id] == product.id }
    expect(debt_row[:purchased_amount]).to eq(2)
    expect(debt_row[:sold_amount]).to eq(5)
  end
end

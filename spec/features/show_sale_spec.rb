# frozen_string_literal: true

require "rails_helper"

describe "Sale show page" do
  before { sign_in_as_admin }
  after { log_out }

  let(:sale) { create(:sale) }
  let(:link_label) { "Link with purchases" }

  context "when the nav link should be hidden" do
    before do
      sale.update!(status: "on-hold", shopify_id: nil, shopify_name: nil, woo_id: nil)
      product = create(:product)
      sale_item = create(:sale_item, sale: sale, product: product, variant: nil, qty: 1)
      create(:purchase_item, sale_item:, purchase: create(:purchase, product: product), warehouse: create(:warehouse))
    end

    it "does not show the link when all conditions are false" do
      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when only #active? is true" do
      sale.update!(status: Sale.active_status_names.first, shopify_id: nil, shopify_name: nil, woo_id: nil)
      product = create(:product)
      sale_item = create(:sale_item, sale: sale, product: product, variant: nil, qty: 1)
      create(:purchase_item, sale_item:, purchase: create(:purchase, product: product), warehouse: create(:warehouse))

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when only #unlinked_sale_items? is true" do
      sale.update!(status: "on-hold", shopify_id: nil, shopify_name: nil, woo_id: nil)
      product = create(:product)
      create(:sale_item, sale: sale, product: product, variant: nil, qty: 2)
      create(:purchase_item, purchase: create(:purchase, product: product), warehouse: create(:warehouse))

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end
  end

  context "when the sale is identified by shopify name" do
    let(:customer) { create(:customer, email: "user@example.com") }
    let(:sale) { create(:sale, customer:, status: "pre-ordered", shopify_name: "HSCM#1746", shopify_id: nil, woo_id: nil) }

    it "shows the shop title h1" do
      visit sale_path(sale)

      expect(page).to have_css("h1", text: "Sale HSCM#1746")
    end

    it "shows the status/email h2" do
      visit sale_path(sale)

      expect(page).to have_css("h2", text: "Pre Ordered | user@example.com")
    end

    it "shows the shared fetch icon" do
      visit sale_path(sale)

      expect(page).to have_link("Fetch")
      expect(page).to have_css("menu.nav_menu a.btn-rounded svg")
    end
  end

  context "when the sale is identified by Shopify GIDs" do
    let(:customer) { create(:customer, email: "user@example.com") }
    let(:sale) do
      create(
        :sale,
        customer:,
        status: "pre-ordered",
        shopify_name: nil,
        shopify_id: "gid://shopify/Order/7383283466569",
        woo_id: nil
      )
    end

    before do
      customer.upsert_shopify_info!(store_id: "gid://shopify/Customer/9341147185481")
      sale.shopify_info.update!(store_id: "gid://shopify/Order/7383283466569")
    end

    it "shows short Shopify ids instead of the full GIDs" do
      visit sale_path(sale)

      expect(page).to have_css("h1", text: "Sale 7383283466569")
      expect(page).to have_text("9341147185481")
      expect(page).to have_text("7383283466569")
      expect(page).to have_no_text("gid://shopify/Customer/9341147185481")
      expect(page).to have_no_text("gid://shopify/Order/7383283466569")
    end
  end

  context "when the nav link should be visible" do
    it "shows the link when all conditions are true" do
      active_sale = create(:sale, status: Sale.active_status_names.first)
      product = create(:product)
      create(:sale_item, sale: active_sale, product:, variant: nil, qty: 2)
      create(:purchase_item, purchase: create(:purchase, product: product))

      visit sale_path(active_sale)

      expect(page).to have_css("a.btn-lightblue", text: link_label)
    end
  end
end

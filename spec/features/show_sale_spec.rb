# frozen_string_literal: true

require "rails_helper"

describe "Sale show page" do
  before { sign_in_as_admin }
  after { log_out }

  let(:sale) { create(:sale) }
  let(:link_label) { "Link with purchases" }

  context "when the nav link should be hidden" do
    before do
      allow(sale).to receive_messages(active?: false, unlinked_sale_items?: false)
      allow(PurchaseItem).to receive(:available_for_product_linking).and_return([])

      product = create(:product)
      create(:sale_item, sale: sale, product: product, qty: 2)
      create(:purchase_item, product: product)
    end

    it "does not show the link when all conditions are false" do
      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when only #active? is true" do
      allow(sale).to receive(:active?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when only #unlinked_sale_items? is true" do
      allow(sale).to receive(:unlinked_sale_items?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end
  end

  context "when the nav link should be visible" do
    it "shows the link when all conditions are true" do
      active_sale = create(:sale, status: Sale.active_status_names.first)
      product = create(:product)
      create(:sale_item, sale: active_sale, product:, qty: 2)
      create(:purchase_item, product:)

      visit sale_path(active_sale)

      expect(page).to have_link(link_label, href: link_purchase_items_sale_path(active_sale.friendly_id))
    end
  end
end

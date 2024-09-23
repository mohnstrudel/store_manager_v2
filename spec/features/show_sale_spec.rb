require "rails_helper"

describe "Sale show page" do
  let(:sale) { create(:sale) }
  let(:link_label) { "🔗 Link with Purchased Products" }

  context "when the nav link should be hidden" do
    before do
      allow(sale).to receive_messages(active?: false, has_unlinked_purchased_products?: false)
      allow(sale.products).to receive(:any?).and_return(false)
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

    it "does not show the link when only #has_unlinked_purchased_products? is true" do
      allow(sale).to receive(:has_unlinked_purchased_products?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when only #products.any? is true" do
      allow(sale.products).to receive(:any?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when #active? and #has_unlinked_purchased_products? are true" do
      allow(sale).to receive_messages(active?: true, has_unlinked_purchased_products?: true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when #active? and #products.any? are true" do
      allow(sale).to receive(:active?).and_return(true)
      allow(sale.products).to receive(:any?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end

    it "does not show the link when #has_unlinked_purchased_products? and #products.any? are true" do
      allow(sale).to receive(:has_unlinked_purchased_products?).and_return(true)
      allow(sale.products).to receive(:any?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end
  end

  context "when the nav link should be visible" do
    before do
      product = create(:product)
      create(:product_sale, sale: sale, product: product, qty: 2)
      create(:purchased_product, product: product)
    end

    it "shows the link when all conditions are true" do
      allow(sale).to receive_messages(active?: true, has_unlinked_purchased_products?: true)
      allow(sale.products).to receive(:any?).and_return(true)

      visit sale_path(sale)

      expect(page).to have_link(link_label, href: link_purchased_products_sale_path(sale.friendly_id))
    end
  end
end

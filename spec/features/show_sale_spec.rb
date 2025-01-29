require "rails_helper"

describe "Sale show page" do
  let(:sale) { create(:sale) }
  let(:link_label) { "🔗 Link with purchases" }

  context "when the nav link should be hidden" do
    before do
      allow(sale).to receive_messages(active?: false, has_unlinked_product_sales?: false)
      allow(PurchasedProduct).to receive(:without_product_sales).and_return([])

      product = create(:product)
      create(:product_sale, sale: sale, product: product, qty: 2)
      create(:purchased_product, product: product)
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

    it "does not show the link when only #has_unlinked_product_sales? is true" do
      allow(sale).to receive(:has_unlinked_product_sales?).and_return(true)

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
      allow(sale).to receive_messages(active?: true, has_unlinked_product_sales?: true)

      visit sale_path(sale)

      expect(page).to have_link(link_label, href: link_purchased_products_sale_path(sale.friendly_id))
    end
  end
end

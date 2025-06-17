require "rails_helper"

describe "Sale show page" do
  let(:sale) { create(:sale) }
  let(:link_label) { "🔗 Link with purchases" }

  context "when the nav link should be hidden" do
    before do
      allow(sale).to receive_messages(active?: false, has_unlinked_sale_items?: false)
      allow(PurchaseItem).to receive(:without_sale_items).and_return([])

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

    it "does not show the link when only #has_unlinked_sale_items? is true" do
      allow(sale).to receive(:has_unlinked_sale_items?).and_return(true)

      visit sale_path(sale)

      expect(page).not_to have_link(link_label)
    end
  end

  context "when the nav link should be visible" do
    before do
      product = create(:product)
      create(:sale_item, sale: sale, product: product, qty: 2)
      create(:purchase_item, product: product)
    end

    it "shows the link when all conditions are true" do
      allow(sale).to receive_messages(active?: true, has_unlinked_sale_items?: true)

      visit sale_path(sale)

      expect(page).to have_link(link_label, href: link_purchase_items_sale_path(sale.friendly_id))
    end
  end
end

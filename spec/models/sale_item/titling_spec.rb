# frozen_string_literal: true

require "rails_helper"

RSpec.describe SaleItem::Titling do
  describe "#title" do
    it "returns the product title when there is no variant" do
      sale_item = create(:sale_item, variant: nil)

      expect(sale_item.title).to eq(sale_item.product.full_title)
    end

    it "returns the product and variant title when variant is present" do
      sale_item = create(:sale_item)

      expect(sale_item.title).to eq("#{sale_item.product.full_title} → #{sale_item.variant.title}")
    end
  end

  describe "#build_title_for_select" do
    it "includes the id, sale status, title, email, sale id, and woo id" do
      sale_item = create(:sale_item)

      expect(sale_item.build_title_for_select).to include(
        sale_item.id.to_s,
        sale_item.sale.status.titleize,
        sale_item.title,
        sale_item.sale.customer.email,
        "Sale ID: #{sale_item.sale_id}"
      )
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe SaleHelper do
  describe "#sale_summary_for_warehouse" do
    it "formats the sale summary for the warehouse view" do
      sale = create(:sale)

      expect(helper.sale_summary_for_warehouse(sale)).to include(sale.customer.full_name)
    end
  end
end

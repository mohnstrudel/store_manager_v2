require "rails_helper"
require "support/matcher_appear_before"

CANCELLED_SALES_COUNT = 1
CANCELLED_STATUS = "cancelled"

RSpec.describe "Sales index page", js: "true" do
  describe "GET /sales" do
    context "when we have different time and status" do
      before do
        Sale.status_names.each_with_index do |status, idx|
          create(
            :sale,
            status:,
            woo_updated_at: idx.days.ago,
            woo_id: 666 - idx
          )
        end
        visit sales_path
      end

      it "shows all sales except cancelled" do
        expect(page.all("tbody > tr").count).to eql(
          Sale.status_names.count - CANCELLED_SALES_COUNT
        )
      end

      it "do not shows cancelled sales" do
        expect(page).to have_no_text(CANCELLED_STATUS.titleize)
      end

      it "shows sales in correct order" do
        valid_sales = Sale.where.not(status: CANCELLED_STATUS)
        newer_sale = valid_sales.find { |s| s.woo_updated_at > 3.days.ago }
        older_sale = valid_sales.find { |s| s.woo_updated_at < 3.days.ago }

        expect("<td>#{newer_sale.woo_id}</td>").to appear_before("<td>#{older_sale.woo_id}</td>")
      end
    end
  end
end

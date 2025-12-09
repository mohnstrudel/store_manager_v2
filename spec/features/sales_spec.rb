require "rails_helper"
require "support/matcher_appear_before"

CANCELLED_COMPLETED_SALES_COUNT = 4
CANCELLED_STATUS = Sale.cancelled_status_names.map(&:titleize)
COMPLETED_STATUS = Sale.completed_status_names.map(&:titleize)

describe "GET /sales" do
  before { sign_in_as_admin }
  after { log_out }

  context "when we have different time and status" do
    before do
      Sale.status_names.each_with_index do |status, idx|
        create(
          :sale,
          status:,
          woo_created_at: idx.days.ago,
          woo_id: 666 - idx
        )
      end
      visit sales_path
    end

    it "shows all sales except cancelled" do
      expect(page.all("tbody > tr").count).to eql(
        Sale.status_names.count - CANCELLED_COMPLETED_SALES_COUNT
      )
    end

    it "do not shows cancelled sales" do
      expect(page).to have_no_text(CANCELLED_STATUS)
    end

    it "do not shows completed sales" do
      expect(page).to have_no_text(COMPLETED_STATUS)
    end

    it "shows sales in correct order" do
      valid_sales = Sale.except_cancelled_or_completed
      newer_sale = valid_sales.find { |s| s.woo_created_at > 3.days.ago }
      older_sale = valid_sales.find { |s| s.woo_created_at < 3.days.ago }

      # Check that newer sales appear before older ones in the page
      expect(page.body).to match(/#{newer_sale.woo_id}.*#{older_sale.woo_id}/m)
    end
  end
end

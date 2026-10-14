# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyCustomersAboutOrderLocationJob do
  let(:warehouse) { create(:warehouse) }
  let(:purchase) { create(:purchase) }
  let!(:purchase_item_with_sale) do
    create(:purchase_item,
      warehouse:,
      purchase:,
      sale_item: create(:sale_item, sale: create(:sale)))
  end
  let!(:purchase_item_without_sale) do
    create(:purchase_item,
      warehouse:,
      purchase:,
      sale_item: nil)
  end

  describe "#perform" do
    it "creates an explicit-resend intent only for purchased products with sales" do
      described_class.perform_now

      expect(OutboundEmail.pluck(:source, :purchase_item_id)).to eq([["explicit_resend", purchase_item_with_sale.id]])
    end

    it "creates a fresh intent on every run" do
      2.times { described_class.perform_now }

      expect(OutboundEmail.where(purchase_item_id: purchase_item_with_sale.id).count).to eq(2)
    end
  end
end

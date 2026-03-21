# frozen_string_literal: true

require "rails_helper"

describe PurchaseItem do
  describe "#name" do
    subject(:purchase_item) { create(:purchase_item) }

    it { expect(purchase_item.name).to eq(purchase_item.purchase.full_title) }
  end

  describe "#title" do
    subject(:purchase_item) { create(:purchase_item) }

    it { expect(purchase_item.title).to eq("Purchase Item №#{purchase_item.id}") }
  end
end

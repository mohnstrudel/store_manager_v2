# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::PurchaseItemResource do
  describe "purchase_expenses" do
    it "serializes amounts without insignificant trailing zeroes" do
      purchase_item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item:, amount: BigDecimal("10.00"))

      expect(serialize(purchase_item.reload)[:purchase_expenses].first[:amount]).to eq("10")

      expense.update!(amount: BigDecimal("10.50"))
      expect(serialize(purchase_item.reload)[:purchase_expenses].first[:amount]).to eq("10.5")
    end
  end

  describe "new_purchase_expense" do
    it "returns a blank amount for a new, unsaved expense" do
      purchase_item = create(:purchase_item)

      expect(serialize(purchase_item)[:new_purchase_expense][:amount]).to eq("")
    end
  end

  describe "sale_address" do
    it "formats the linked sale's shipping address for the clipboard" do
      sale = create(:sale)
      create(:sale_address, sale:, kind: :shipping)
      purchase_item = create(:purchase_item, sale_item: create(:sale_item, sale:))

      address = serialize(purchase_item.reload)[:sale_address]

      expect(address.lines.first.chomp).to eq(sale.customer.full_name)
      expect(address).to include("Schillerstrasse 68")
    end

    it "is blank without a linked sale" do
      expect(serialize(create(:purchase_item))[:sale_address]).to eq("")
    end
  end

  def serialize(purchase_item)
    described_class.new(purchase_item).serializable_hash.deep_symbolize_keys
  end
end

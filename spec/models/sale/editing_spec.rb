# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  describe "#create_from_form!" do
    let(:customer) { create(:customer) }
    let(:sale) { described_class.new }

    before do
      allow(sale).to receive(:link_purchase_items!)
    end

    it "assigns attributes, saves the sale, and links purchase items" do
      sale.create_from_form!(
        customer_id: customer.id,
        status: "processing",
        total: 100
      )

      aggregate_failures do
        expect(sale).to be_persisted
        expect(sale.customer_id).to eq(customer.id)
        expect(sale.status).to eq("processing")
        expect(sale.total).to eq(BigDecimal("100"))
        expect(sale).to have_received(:link_purchase_items!)
      end
    end
  end

  describe "#apply_form_changes!" do
    let(:sale) { create(:sale, status: "processing", slug: "sale-slug") }

    it "regenerates slug and persists form attributes" do
      previous_slug = sale.slug

      sale.apply_form_changes!(status: "processing", note: "Updated")

      aggregate_failures do
        expect(sale.reload.slug).not_to eq(previous_slug)
        expect(sale.note).to eq("Updated")
      end
    end

    it "syncs the shop order when status changes" do
      allow(sale).to receive(:sync_status_change_to_shop!)

      sale.apply_form_changes!(status: "completed")

      expect(sale).to have_received(:sync_status_change_to_shop!)
    end

    it "does not sync the shop order when status stays the same" do
      allow(sale).to receive(:sync_status_change_to_shop!)

      sale.apply_form_changes!(status: sale.status)

      expect(sale).not_to have_received(:sync_status_change_to_shop!)
    end
  end
end

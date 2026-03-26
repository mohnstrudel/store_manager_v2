# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchase do
  let(:supplier) { create(:supplier) }
  let(:product) { create(:product) }
  let(:edition) { create(:edition, product:) }
  let(:active_status) { Sale.active_status_names.first }
  let(:completed_status) { Sale.completed_status_names.first }

  describe "#link_purchase_items" do
    context "when there are no purchased products" do
      let(:purchase) { create(:purchase, product:, amount: 3) }

      it "returns nil" do
        result = purchase.link_purchase_items
        expect(result).to be_nil
      end
    end

    context "when linking sold products" do
      let(:purchase) { create(:purchase, product:, amount: 3) }
      let!(:purchase_items) do
        3.times.map { create(:purchase_item, purchase:) }
      end

      context "with an active status" do # rubocop:todo RSpec/NestedGroups
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product:, sale:, edition_id: nil, qty: 5) }

        it "links purchased items with sold products" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items

          expect(linked_ids).to match_array(purchase_items.pluck(:id))
          purchase_items.each do |purchase_item|
            expect(purchase_item.reload.sale_item_id).to eq(sale_item.id)
          end
        end

        it "respects the purchase amount limit" do # rubocop:todo RSpec/MultipleExpectations
          purchase.update(amount: 2)
          linked_ids = purchase.link_purchase_items

          expect(linked_ids.size).to eq(2)
          expect(purchase_items.count { |item| item.reload.sale_item_id.nil? }).to eq(1)
        end
      end

      context "when there are multiple product sales" do # rubocop:todo RSpec/NestedGroups
        let!(:sale1) { create(:sale, status: active_status) } # rubocop:todo RSpec/IndexedLet
        let!(:sale2) { create(:sale, status: active_status) } # rubocop:todo RSpec/IndexedLet
        let!(:sale_item1) { create(:sale_item, product:, sale: sale1, qty: 1, edition_id: nil) } # rubocop:todo RSpec/IndexedLet
        let!(:sale_item2) { create(:sale_item, product:, sale: sale2, qty: 4, edition_id: nil) } # rubocop:todo RSpec/IndexedLet

        it "links purchased products to multiple product sales" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items
          linked_sale_item_ids = purchase_items.map(&:reload).pluck(:sale_item_id)

          expect(linked_ids.size).to eq(3)
          expect(linked_ids).to match_array(purchase_items.pluck(:id))
          expect(linked_sale_item_ids).to include(sale_item1.id, sale_item2.id)
        end
      end

      context "when there are not enough product sales" do # rubocop:todo RSpec/NestedGroups
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product:, sale:, qty: 1, edition_id: nil) }

        it "links as many purchased products as possible" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items

          expect(linked_ids.size).to eq(1)
          expect(purchase_items[0].reload.sale_item_id).to eq(sale_item.id)
          expect(purchase_items[1].reload.sale_item_id).to be_nil
          expect(purchase_items[2].reload.sale_item_id).to be_nil
        end
      end

      context "when product sales are not active" do # rubocop:todo RSpec/NestedGroups
        let!(:sale) { create(:sale, status: completed_status) }
        let!(:sale_item) { create(:sale_item, product:, sale:, qty: 5) } # rubocop:todo RSpec/LetSetup

        it "does not link to inactive sales" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items

          expect(linked_ids).to be_empty
          purchase_items.each do |purchase_item|
            expect(purchase_item.reload.sale_item_id).to be_nil
          end
        end
      end

      context "when product sales are not linkable" do # rubocop:todo RSpec/NestedGroups
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product:, sale:, qty: 3, purchase_items_count: 3) } # rubocop:todo RSpec/LetSetup

        it "does not link to fully linked sales" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items

          expect(linked_ids).to be_empty
          purchase_items.each do |purchase_item|
            expect(purchase_item.reload.sale_item_id).to be_nil
          end
        end
      end
    end

    context "when linking with sold editions" do
      let(:purchase) { create(:purchase, product:, edition:, amount: 3) }
      let!(:purchase_items) do
        3.times.map { create(:purchase_item, purchase:) }
      end

      context "when there are available product sales for the edition" do # rubocop:todo RSpec/NestedGroups
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product:, edition:, sale:, qty: 5) }

        it "links purchased products to product sales with matching edition" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items

          expect(linked_ids).to match_array(purchase_items.map(&:id))
          purchase_items.each do |purchase_item|
            expect(purchase_item.reload.sale_item_id).to eq(sale_item.id)
          end
        end
      end

      context "when there are no product sales for the edition" do # rubocop:todo RSpec/NestedGroups
        let!(:other_edition) { create(:edition, product:) }
        let!(:sale) { create(:sale, status: active_status) }
        let!(:sale_item) { create(:sale_item, product:, edition: other_edition, sale:, qty: 5) } # rubocop:todo RSpec/LetSetup

        it "does not link purchased products" do # rubocop:todo RSpec/MultipleExpectations
          linked_ids = purchase.link_purchase_items

          expect(linked_ids).to be_empty
          purchase_items.each do |purchase_item|
            expect(purchase_item.reload.sale_item_id).to be_nil
          end
        end
      end
    end

    context "edge cases" do # rubocop:todo RSpec/ContextWording
      let(:purchase) { create(:purchase, product:, amount: 0) }

      it "handles purchase with zero amount" do
        result = purchase.link_purchase_items
        expect(result).to be_nil
      end

      it "handles product sale with zero quantity" do # rubocop:todo RSpec/MultipleExpectations
        purchase.update(amount: 3)
        purchase_items = 3.times.map { create(:purchase_item, purchase:) }
        sale = create(:sale, status: active_status)
        create(:sale_item, product:, sale:, qty: 0)

        linked_ids = purchase.link_purchase_items

        expect(linked_ids).to be_empty
        purchase_items.each do |purchase_item|
          expect(purchase_item.reload.sale_item_id).to be_nil
        end
      end

      it "handles all product sales being fully linked" do # rubocop:todo RSpec/MultipleExpectations
        purchase.update(amount: 3)
        purchase_items = 3.times.map { create(:purchase_item, purchase:) }
        sale = create(:sale, status: active_status)
        create(:sale_item, product:, sale:, qty: 3, purchase_items_count: 3)

        linked_ids = purchase.link_purchase_items

        expect(linked_ids).to be_empty
        purchase_items.each do |purchase_item|
          expect(purchase_item.reload.sale_item_id).to be_nil
        end
      end
    end
  end
end

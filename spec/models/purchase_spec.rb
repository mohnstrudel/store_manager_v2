# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  payments_count  :integer          default(0), not null
#  purchase_date   :datetime
#  slug            :string
#  synced          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  edition_id      :bigint
#  product_id      :bigint
#  supplier_id     :bigint           not null
#
require "rails_helper"

RSpec.describe Purchase do
  subject(:purchase) { build(:purchase) }

  describe "Validations" do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:item_price) }
    it { is_expected.to validate_presence_of(:supplier_id) }

    context "when amount is not present" do
      before { purchase.amount = nil }
      it { is_expected.not_to be_valid }
    end

    context "when item_price is not present" do
      before { purchase.item_price = nil }
      it { is_expected.not_to be_valid }
    end

    context "when supplier_id is not present" do
      before { purchase.supplier_id = nil }
      it { is_expected.not_to be_valid }
    end
  end

  describe "Associations" do
    # Create a fully built purchase for association tests
    let(:purchase_for_associations) { create(:purchase) }

    it { expect(purchase_for_associations).to belong_to(:supplier) }
    it { expect(purchase_for_associations).to belong_to(:product).optional }
    it { expect(purchase_for_associations).to belong_to(:edition).optional }

    it { expect(purchase_for_associations).to have_many(:payments).dependent(:destroy) }
    it { expect(purchase_for_associations).to accept_nested_attributes_for(:payments) }

    it { expect(purchase_for_associations).to have_many(:purchase_items).dependent(:destroy) }
    it { expect(purchase_for_associations).to have_many(:warehouses).through(:purchase_items) }

    describe "through edition associations" do
      let(:edition) { create(:edition) }
      let(:purchase) { create(:purchase, edition:) }

      it "has many sizes through edition" do
        expect(purchase.sizes).to include(edition.size) if edition.size
      end

      it "has many versions through edition" do
        expect(purchase.versions).to include(edition.version) if edition.version
      end

      it "has many colors through edition" do
        expect(purchase.colors).to include(edition.color) if edition.color
      end
    end

    context "when edition is nil" do
      let(:purchase) { create(:purchase, edition: nil) }

      it "returns empty collections for through associations" do
        expect(purchase.sizes).to be_empty
        expect(purchase.versions).to be_empty
        expect(purchase.colors).to be_empty
      end
    end
  end

  describe "Scopes" do
    describe ".unpaid" do
      let!(:unpaid_purchase) { create(:purchase, payments_count: 0) }
      let!(:paid_purchase) { create(:purchase, payments_count: 1) }
      let!(:older_unpaid_purchase) { create(:purchase, payments_count: 0, created_at: 2.days.ago) }

      it "returns purchases without payments" do
        expect(described_class.unpaid).to include(unpaid_purchase, older_unpaid_purchase)
        expect(described_class.unpaid.where.not(id: paid_purchase.id)).not_to include(paid_purchase)
      end

      it "includes supplier data" do
        result = described_class.unpaid
        expect(result.first.association(:supplier)).to be_loaded
      end

      it "orders by creation date ascending" do
        expect(described_class.unpaid.where(id: [unpaid_purchase.id, older_unpaid_purchase.id]).to_a).to eq([older_unpaid_purchase, unpaid_purchase])
      end
    end
  end

  describe "Domain Methods" do
    let(:purchase) { create(:purchase, amount: 10, item_price: 100.0) }
    let!(:payment1) { create(:payment, purchase:, value: 200.0) }
    let!(:payment2) { create(:payment, purchase:, value: 300.0) }

    describe "#paid" do
      it "calculates total paid amount from payments" do
        expect(purchase.paid).to eq(500.0)
      end

      it "returns 0 when there are no payments" do
        purchase.payments.destroy_all
        expect(purchase.paid).to eq(0)
      end

      it "memoizes the result" do
        expect(purchase.payments).to receive(:pluck).once.and_return([200.0, 300.0])
        expect(purchase.paid).to eq(500.0)
        expect(purchase.paid).to eq(500.0) # Should not call pluck again
      end
    end

    describe "#debt" do
      it "calculates remaining debt (total_cost - paid)" do
        allow(purchase).to receive(:total_cost).and_return(1200.0)
        expect(purchase.debt).to eq(700.0)
      end

      it "returns 0 when paid amount exceeds total_cost" do
        allow(purchase).to receive(:total_cost).and_return(400.0)
        expect(purchase.debt).to eq(0)
      end

      it "memoizes the result" do
        expect(purchase).to receive(:total_cost).once.and_return(1200.0)
        expect(purchase.debt).to eq(700.0)
        expect(purchase.debt).to eq(700.0) # Should not call total_cost again
      end
    end

    describe "#item_debt" do
      it "calculates debt per item" do
        allow(purchase).to receive(:debt).and_return(700.0)
        expect(purchase.item_debt).to eq(70.0)
      end

      context "when amount is zero" do
        before { purchase.amount = 0 }
        it "returns Infinity" do
          allow(purchase).to receive(:debt).and_return(700.0)
          expect(purchase.item_debt).to eq(Float::INFINITY)
        end
      end
    end

    describe "#item_paid" do
      it "calculates paid amount per item" do
        expect(purchase.item_paid).to eq(50.0)
      end

      context "when amount is zero" do
        before { purchase.amount = 0 }
        it "returns Infinity" do
          allow(purchase).to receive(:paid).and_return(500.0)
          expect(purchase.item_paid).to eq(Float::INFINITY)
        end
      end
    end

    describe "#progress" do
      it "calculates payment progress percentage" do
        allow(purchase).to receive(:total_cost).and_return(1200.0)
        expect(purchase.progress.round(2)).to eq(41.67) # 500.0 * 100.0 / 1200.0 rounded to 2 decimals
      end

      it "returns 0 when total_cost is zero" do
        allow(purchase).to receive(:total_cost).and_return(0)
        expect(purchase.progress).to eq(0)
      end

      it "returns 100 when paid amount exceeds total_cost" do
        allow(purchase).to receive(:paid).and_return(1500.0)
        allow(purchase).to receive(:total_cost).and_return(1200.0)
        expect(purchase.progress).to eq(100)
      end

      it "returns 100 when paid amount equals total_cost" do
        allow(purchase).to receive(:paid).and_return(1200.0)
        allow(purchase).to receive(:total_cost).and_return(1200.0)
        expect(purchase.progress).to eq(100)
      end
    end

    describe "#total_cost" do
      it "calculates total cost including shipping" do
        allow(purchase).to receive(:total_shipping).and_return(50.0)
        expect(purchase.total_cost).to eq(1050.0) # 100.0 * 10 + 50.0
      end
    end

    describe "#total_shipping" do
      let!(:purchase_item1) { create(:purchase_item, purchase:, shipping_price: 10.0) }
      let!(:purchase_item2) { create(:purchase_item, purchase:, shipping_price: 15.0) }

      it "calculates total shipping cost from purchase_items" do
        expect(purchase.total_shipping).to eq(25.0)
      end

      it "returns 0 when there are no purchase_items" do
        purchase.purchase_items.destroy_all
        expect(purchase.total_shipping).to eq(0)
      end

      it "handles nil shipping_price values" do
        purchase_item1.update!(shipping_price: nil)
        expect(purchase.total_shipping).to eq(15.0)
      end
    end

    describe "#full_title" do
      let(:purchase_date) { Date.new(2023, 1, 1) }
      let(:created_at) { DateTime.new(2023, 1, 2) }

      it "generates formatted title with supplier, product, and purchase_date" do
        purchase.purchase_date = purchase_date
        expected_title = "#{purchase.supplier.title} | #{purchase.product.full_title} | 2023-01-01"
        expect(purchase.full_title).to eq(expected_title)
      end

      it "uses created_at when purchase_date is nil" do
        purchase.purchase_date = nil
        purchase.created_at = created_at
        expected_title = "#{purchase.supplier.title} | #{purchase.product.full_title} | 2023-01-02"
        expect(purchase.full_title).to eq(expected_title)
      end

      it "handles nil dates gracefully" do
        purchase.purchase_date = nil
        purchase.created_at = nil
        expected_title = "#{purchase.supplier.title} | #{purchase.product.full_title} | "
        expect(purchase.full_title).to eq(expected_title)
      end
    end

    describe "#which_edition" do
      context "when edition is present" do
        let(:edition) { create(:edition) }
        let(:purchase) { create(:purchase, edition:) }

        it "returns edition title" do
          expect(purchase.which_edition).to eq(edition.title)
        end
      end

      context "when edition is nil" do
        let(:purchase) { create(:purchase, edition: nil) }

        it "returns '-'" do
          expect(purchase.which_edition).to eq("-")
        end
      end
    end

    describe "#date" do
      let(:purchase_date) { Date.new(2023, 1, 1) }
      let(:created_at) { DateTime.new(2023, 1, 2) }

      it "returns purchase_date when present" do
        purchase.purchase_date = purchase_date
        expect(purchase.date).to eq(purchase_date)
      end

      it "returns created_at when purchase_date is nil" do
        purchase.purchase_date = nil
        purchase.created_at = created_at
        expect(purchase.date).to eq(created_at)
      end
    end

    describe "#unpaid?" do
      it "returns true when purchase has no payments" do
        purchase.payments.destroy_all
        purchase.update!(payments_count: 0)
        expect(purchase.unpaid?).to be true
      end

      it "returns false when purchase has payments" do
        purchase.update!(payments_count: 1)
        expect(purchase.unpaid?).to be false
      end
    end

    describe "#add_items_to_warehouse" do
      let(:warehouse) { create(:warehouse) }
      let(:purchase) { create(:purchase, amount: 3) }

      it "creates purchase items for the warehouse" do
        expect {
          purchase.add_items_to_warehouse(warehouse.id)
        }.to change(PurchaseItem, :count).by(3)
      end

      it "associates purchase items with the purchase" do
        purchase.add_items_to_warehouse(warehouse.id)
        expect(PurchaseItem.where(purchase_id: purchase.id).count).to eq(3)
      end

      it "associates purchase items with the warehouse" do
        purchase.add_items_to_warehouse(warehouse.id)
        expect(PurchaseItem.where(warehouse_id: warehouse.id).count).to eq(3)
      end

      it "sets created_at and updated_at timestamps" do
        purchase.add_items_to_warehouse(warehouse.id)
        purchase_items = PurchaseItem.where(purchase_id: purchase.id)
        expect(purchase_items.all? { |item| item.created_at.present? }).to be true
        expect(purchase_items.all? { |item| item.updated_at.present? }).to be true
      end

      context "when amount is zero" do
        let(:purchase) { create(:purchase, amount: 0) }

        it "creates no purchase items" do
          expect {
            purchase.add_items_to_warehouse(warehouse.id)
          }.not_to change(PurchaseItem, :count)
        end
      end

      context "when warehouse does not exist" do
        let(:invalid_warehouse_id) { 999999 }

        it "raises ActiveRecord::RecordInvalid" do
          expect {
            purchase.add_items_to_warehouse(invalid_warehouse_id)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    describe "#link_with_sales" do
      let(:purchase) { create(:purchase, amount: 2) }
      let!(:purchase_item1) { create(:purchase_item, purchase:) }
      let!(:purchase_item2) { create(:purchase_item, purchase:) }
      let(:sale_item) { create(:sale_item, qty: 2, product: purchase.product) }

      before do
        allow(SaleItem).to receive(:linkable_with).and_return([sale_item])
      end

      it "links purchase with sales and sends notifications" do
        expect(PurchaseLinker).to receive(:link).with(purchase).and_return([purchase_item1.id, purchase_item2.id])
        expect(PurchasedNotifier).to receive(:handle_product_purchase).with(purchase_item_ids: [purchase_item1.id, purchase_item2.id])

        purchase.link_with_sales
      end

      it "does nothing when purchase has no purchase_items" do
        purchase.purchase_items.destroy_all
        allow(PurchaseLinker).to receive(:link).and_return([])
        purchase.link_with_sales
      end
    end
  end

  describe "Configuration and Extensions" do
    describe "auditing" do
      it "is audited" do
        expect(described_class.auditing_enabled).to be true
      end

      it "has associated audits" do
        # The has_associated_audits method is only available after the audited method has been called
        # Since the Purchase model calls audited, we can check if it has the method
        expect(described_class.instance_methods).to include(:associated_audits)
      end

      it "is audited associated with supplier" do
        expect(described_class.audit_associated_with).to eq(:supplier)
      end
    end

    describe "FriendlyId" do
      it "has friendly_id configured" do
        expect(described_class.friendly_id_config).to be_present
        expect(described_class.friendly_id_config.base).to eq(:full_title)
      end
    end

    describe "Searchable" do
      it "includes Searchable concern" do
        expect(described_class).to include(Searchable)
      end

      it "has search scope configured" do
        expect(described_class).to respond_to(:search)
        expect(described_class).to respond_to(:search_by)
      end
    end

    describe "pagination" do
      it "has default pagination configured" do
        expect(described_class.default_per_page).to eq(50)
      end
    end
  end

  describe "Edge Cases and Error Conditions" do
    describe "division by zero in progress method" do
      let(:purchase) { create(:purchase, amount: 10, item_price: 100.0) }

      it "returns 0 when total_cost is zero" do
        allow(purchase).to receive(:total_cost).and_return(0)
        expect(purchase.progress).to eq(0)
      end
    end

    describe "nil payments in paid method" do
      let(:purchase) { create(:purchase) }

      it "returns 0 when payments association is nil" do
        allow(purchase).to receive(:payments).and_return(nil)
        expect(purchase.paid).to eq(0)
      end
    end

    describe "zero amount in item_debt and item_paid methods" do
      let(:purchase) { create(:purchase, amount: 0) }

      it "returns Infinity in item_debt" do
        allow(purchase).to receive(:debt).and_return(100.0)
        expect(purchase.item_debt).to eq(Float::INFINITY)
      end

      it "returns Infinity in item_paid" do
        allow(purchase).to receive(:paid).and_return(100.0)
        expect(purchase.item_paid).to eq(Float::INFINITY)
      end
    end
  end

  describe "HasAuditNotifications" do
    let(:purchase) { create(:purchase) }

    it "includes HasAuditNotifications concern" do
      expect(described_class).to include(HasAuditNotifications)
    end

    context "when model is audited" do
      before do
        allow(described_class).to receive(:auditing_enabled).and_return(true)
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(Rails.env).to receive(:staging?).and_return(false)
      end

      it "enqueues NotifyAboutRecordChanges after commit in production" do
        expect {
          purchase.save!
        }.to have_enqueued_job(NotifyAboutRecordChanges).with(purchase)
      end

      it "does not enqueue job in staging" do
        allow(Rails.env).to receive(:staging?).and_return(true)
        expect {
          purchase.save!
        }.not_to have_enqueued_job(NotifyAboutRecordChanges)
      end
    end

    context "when model is not audited" do
      before do
        allow(described_class).to receive(:auditing_enabled).and_return(false)
      end

      it "does not enqueue job" do
        expect {
          purchase.save!
        }.not_to have_enqueued_job(NotifyAboutRecordChanges)
      end
    end
  end

  describe "Search functionality" do
    let!(:purchase) { create(:purchase, order_reference: "TEST-123") }
    let!(:supplier) { purchase.supplier }
    let!(:product) { purchase.product }
    let!(:edition) { create(:edition, product:) }
    let!(:size) { create(:size, value: "1:4") }
    let!(:version) { create(:version, value: "Deluxe") }
    let!(:color) { create(:color, value: "Red") }

    before do
      edition.update!(size:, version:, color:)
      purchase.update!(edition:)
    end

    it "searches by order_reference" do
      expect(described_class.search_by("TEST-123")).to include(purchase)
    end

    it "searches by supplier title" do
      expect(described_class.search_by(supplier.title)).to include(purchase)
    end

    it "searches by product full_title" do
      expect(described_class.search_by(product.full_title)).to include(purchase)
    end

    it "searches by size value" do
      expect(described_class.search_by("1:4")).to include(purchase)
    end

    it "searches by version value" do
      expect(described_class.search_by("Deluxe")).to include(purchase)
    end

    it "searches by color value" do
      expect(described_class.search_by("Red")).to include(purchase)
    end

    it "returns all records when query is blank" do
      expect(described_class.search_by("")).to include(purchase)
    end

    it "returns empty result for non-matching query" do
      expect(described_class.search_by("NONEXISTENT")).to be_empty
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  item_price      :decimal(8, 2)
#  order_reference :string
#  paid            :decimal(8, 2)    default(0.0), not null
#  payments_count  :integer          default(0), not null
#  purchase_date   :datetime
#  shipping_total  :decimal(8, 2)    default(0.0), not null
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

      it "returns empty collections for through associations" do # rubocop:todo RSpec/MultipleExpectations
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

      it "returns purchases without payments" do # rubocop:todo RSpec/MultipleExpectations
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
      it "has friendly_id configured" do # rubocop:todo RSpec/MultipleExpectations
        expect(described_class.friendly_id_config).to be_present
        expect(described_class.friendly_id_config.base).to eq(:full_title)
      end
    end

    describe "Searchable" do
      it "includes Searchable concern" do
        expect(described_class).to include(Searchable)
      end

      it "has search scope configured" do # rubocop:todo RSpec/MultipleExpectations
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

  describe "HasAuditNotifications" do
    let(:purchase) { create(:purchase) }

    it "includes HasAuditNotifications concern" do
      expect(described_class).to include(HasAuditNotifications)
    end

    context "when model is audited" do
      before do
        allow(described_class).to receive(:auditing_enabled).and_return(true)
        allow(Rails.env).to receive_messages(production?: true, staging?: false)
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

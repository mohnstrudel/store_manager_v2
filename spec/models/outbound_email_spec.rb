# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: outbound_emails
#
#  id               :bigint           not null, primary key
#  accepted_at      :datetime
#  attempts         :integer          default(0), not null
#  body             :text
#  last_attempt_at  :datetime
#  last_error       :string
#  mail_kind        :string
#  product_title    :text
#  recipient        :string
#  recipient_name   :string
#  sender           :string
#  source           :string           not null
#  state            :string           default("pending"), not null
#  subject          :string
#  created_at       :datetime         not null
#  customer_id      :bigint
#  purchase_item_id :bigint           not null
#  sale_item_id     :bigint           not null
#  warehouse_id     :bigint           not null
#
RSpec.describe OutboundEmail do
  describe "assumed baseline" do
    it "is distinguishable from a message and carries no message, attempts, or acceptance" do
      baseline = create(:outbound_email, :assumed_baseline)

      expect(baseline).to have_attributes(
        source: "baseline", state: "assumed_baseline", recipient: nil, body: nil,
        attempts: 0, last_attempt_at: nil, accepted_at: nil
      )
    end

    it "cannot be stored with a recipient" do
      expect { create(:outbound_email, :assumed_baseline, recipient: "buyer@example.com") }
        .to raise_error(ActiveRecord::StatementInvalid, /outbound_emails_baseline_or_message/)
    end

    it "is not queued for delivery" do
      create(:outbound_email, :assumed_baseline)
      pending_email = create(:outbound_email)

      expect(described_class.pending).to contain_exactly(pending_email)
    end
  end

  describe "acceptance" do
    it "requires accepted_at exactly when accepted" do
      expect { create(:outbound_email, state: "accepted", accepted_at: nil) }
        .to raise_error(ActiveRecord::StatementInvalid, /outbound_emails_accepted_at_only_when_accepted/)
    end
  end

  describe "history" do
    it "keeps rows and message snapshots when the referenced domain records are deleted" do
      warehouse = create(:warehouse)
      sale_item = create(:sale_item)
      purchase_item = create(:purchase_item, warehouse:, sale_item:)
      email = create(:outbound_email,
        purchase_item_id: purchase_item.id, sale_item_id: sale_item.id, warehouse_id: warehouse.id)
      baseline = create(:outbound_email, :assumed_baseline,
        purchase_item_id: purchase_item.id, sale_item_id: sale_item.id, warehouse_id: warehouse.id)

      purchase_item.destroy!
      sale_item.destroy!

      expect(described_class.where(purchase_item_id: purchase_item.id, sale_item_id: sale_item.id))
        .to contain_exactly(email, baseline)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261013141000_seed_outbound_email_baseline")

RSpec.describe SeedOutboundEmailBaseline do
  def run_up
    migration = described_class.new
    migration.suppress_messages { migration.migrate(:up) }
  end

  it "records an assumed baseline for every linked purchase item, with or without customer email, and none for unlinked items" do
    emailed_sale_item = create(:sale_item, sale: create(:sale, customer: create(:customer, email: "buyer@example.com")))
    emailless_sale_item = create(:sale_item, sale: create(:sale, customer: create(:customer, email: nil)))
    warehouse = create(:warehouse)
    emailed = create(:purchase_item, warehouse:, sale_item: emailed_sale_item)
    emailless = create(:purchase_item, warehouse:, sale_item: emailless_sale_item)
    unlinked = create(:purchase_item, warehouse:)

    run_up

    expect(OutboundEmail.pluck(:purchase_item_id, :sale_item_id, :warehouse_id)).to contain_exactly(
      [emailed.id, emailed_sale_item.id, warehouse.id],
      [emailless.id, emailless_sale_item.id, warehouse.id]
    )
    expect(OutboundEmail.where(purchase_item_id: unlinked.id)).to be_empty
  end

  it "stores baseline rows without message, attempts, or acceptance" do
    create(:purchase_item, sale_item: create(:sale_item))

    run_up

    expect(OutboundEmail.sole).to have_attributes(
      source: "baseline", state: "assumed_baseline", mail_kind: nil, recipient: nil,
      sender: nil, subject: nil, body: nil, attempts: 0, last_attempt_at: nil, accepted_at: nil
    )
  end
end

# frozen_string_literal: true

namespace :outbound_emails do
  task status: :environment do
    puts "baseline_rows=#{OutboundEmail.assumed_baseline.count}"
    puts "linked_purchase_items=#{PurchaseItem.where.not(sale_item_id: nil).count}"
    puts "pending_older_than_15_min=#{OutboundEmail.pending.where(created_at: ...15.minutes.ago).count}"
  end
end

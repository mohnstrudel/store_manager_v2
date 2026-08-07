# frozen_string_literal: true

desc "One-time backfill: reassign Seal Subscriptions installment payments from the placeholder product to the real product they were paying towards"
task backfill_installment_sale_items: :environment do
  result = Sale::InstallmentBackfill.call

  puts "Reassigned #{result.reassigned_count} sale item(s)."

  if result.unresolved_sale_item_ids.any?
    puts "Could not resolve #{result.unresolved_sale_item_ids.size} sale item(s), left on the placeholder product: #{result.unresolved_sale_item_ids.join(", ")}"
  end
end

# frozen_string_literal: true

class SeedOutboundEmailBaseline < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO outbound_emails (source, state, purchase_item_id, sale_item_id, warehouse_id, attempts, created_at)
      SELECT 'baseline', 'assumed_baseline', id, sale_item_id, warehouse_id, 0, CURRENT_TIMESTAMP
      FROM purchase_items
      WHERE sale_item_id IS NOT NULL
    SQL
  end

  def down
    execute "DELETE FROM outbound_emails WHERE source = 'baseline'"
  end
end

# frozen_string_literal: true

class AddShippedAtToPurchaseItems < ActiveRecord::Migration[8.1]
  def up
    add_column :purchase_items, :shipped_at, :datetime

    execute <<~SQL.squish
      UPDATE purchase_items
      SET shipped_at = (
        SELECT MAX(audits.created_at)
        FROM audits
        WHERE audits.auditable_type = 'PurchaseItem'
          AND audits.auditable_id = purchase_items.id
          AND CASE jsonb_typeof(audits.audited_changes -> 'tracking_number')
                WHEN 'array' THEN audits.audited_changes -> 'tracking_number' ->> -1
                ELSE audits.audited_changes ->> 'tracking_number'
              END = purchase_items.tracking_number
      )
      WHERE purchase_items.tracking_number <> ''
    SQL
  end

  def down
    remove_column :purchase_items, :shipped_at
  end
end

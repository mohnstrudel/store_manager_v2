# frozen_string_literal: true

class AddWarehouseArrivedAtToPurchaseItems < ActiveRecord::Migration[8.1]
  def up
    add_column :purchase_items, :warehouse_arrived_at, :datetime
    add_index :purchase_items, [:warehouse_id, :warehouse_arrived_at, :id],
      name: "index_purchase_items_on_warehouse_arrival"

    backfill_warehouse_arrivals

    change_column_null :purchase_items, :warehouse_arrived_at, false
  end

  def down
    remove_index :purchase_items, name: "index_purchase_items_on_warehouse_arrival"
    remove_column :purchase_items, :warehouse_arrived_at
  end

  private

  def backfill_warehouse_arrivals
    MigrationPurchaseItem.includes(:audits).find_each do |purchase_item|
      purchase_item.update_columns(warehouse_arrived_at: purchase_item.current_warehouse_arrived_at)
    end
  end

  class MigrationPurchaseItem < ApplicationRecord
    self.table_name = "purchase_items"

    has_many :audits,
      -> { where(auditable_type: "PurchaseItem").order(:created_at) },
      class_name: "AddWarehouseArrivedAtToPurchaseItems::MigrationAudit",
      foreign_key: :auditable_id,
      inverse_of: false

    def current_warehouse_arrived_at
      warehouse_entry_times.max || created_at
    end

    private

    def warehouse_entry_times
      audits.filter_map do |audit|
        next unless moved_warehouse_id_for(audit) == warehouse_id

        audit.created_at
      end
    end

    def moved_warehouse_id_for(audit)
      change = audit.audited_changes["warehouse_id"]
      value = change.is_a?(Array) ? change.last : change
      value&.to_i
    end
  end

  class MigrationAudit < ApplicationRecord
    self.table_name = "audits"
  end
end

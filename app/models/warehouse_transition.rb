# == Schema Information
#
# Table name: warehouse_transitions
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  from_warehouse_id :bigint
#  notification_id   :bigint           not null
#  to_warehouse_id   :bigint
#
class WarehouseTransition < ApplicationRecord
  db_belongs_to :notification
  db_belongs_to :from_warehouse, class_name: "Warehouse"
  db_belongs_to :to_warehouse, class_name: "Warehouse"

  validates_db_presence_of :from_warehouse, :to_warehouse
  validates_db_uniqueness_of :from_warehouse_id,
    scope: [:to_warehouse_id, :notification_id]
end

# frozen_string_literal: true
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
  #
  # == Concerns
  #
  include HasAuditNotifications

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited associated_with: :notification

  #
  # == Validations
  #
  validates_db_presence_of :from_warehouse, :to_warehouse
  validates_db_uniqueness_of :from_warehouse_id,
    scope: [:to_warehouse_id, :notification_id]

  #
  # == Associations
  #
  db_belongs_to :notification
  db_belongs_to :from_warehouse, class_name: "Warehouse"
  db_belongs_to :to_warehouse, class_name: "Warehouse"

  #
  # == Scopes
  #
  # (none)

  #
  # == Class Methods
  #
  # (none)

  #
  # == Domain Methods
  #
  # (none)
end

# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  event_type :integer          default("product_purchased"), not null
#  name       :string           not null
#  status     :integer          default("disabled"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Notification < ApplicationRecord
  audited

  enum :status, {
    disabled: 0,
    active: 1
  }, default: :disabled

  enum :event_type, {
    product_purchased: 0,
    warehouse_changed: 1
  }, default: :product_purchased

  has_many :warehouse_transitions, dependent: :nullify
end

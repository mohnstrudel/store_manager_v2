# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  external_name             :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
FactoryBot.define do
  factory :warehouse do
    name { "Virtual Warehouse" }
    external_name { "In Production" }
    container_tracking_number { "666" }
    courier_tracking_url { "" }
    cbm { "42" }
    is_default { false }
  end
end

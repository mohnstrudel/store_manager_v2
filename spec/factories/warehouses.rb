# frozen_string_literal: true
# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  desc_de                   :string
#  desc_en                   :string
#  external_name_de          :string
#  external_name_en          :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  position                  :integer          default(1), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
FactoryBot.define do
  factory :warehouse do
    sequence(:name) { |n| "Warehouse #{n}" }
    sequence(:external_name_de) { |n| "Externer Name #{n}" }
    sequence(:external_name_en) { |n| "External Name #{n}" }
    sequence(:position) { |n| n }
    desc_en { "English Description" }
    desc_de { "German Description" }
    is_default { false }

    trait :default do
      is_default { true }
    end
  end
end

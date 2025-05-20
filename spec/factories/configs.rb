# == Schema Information
#
# Table name: configs
#
#  id                    :bigint           not null, primary key
#  sales_hook_status     :integer          default("disabled")
#  shopify_products_sync :datetime
#  shopify_sales_sync    :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
FactoryBot.define do
  factory :config do
    sales_hook_status { 1 }
  end
end

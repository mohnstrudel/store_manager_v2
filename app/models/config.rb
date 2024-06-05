# == Schema Information
#
# Table name: configs
#
#  id                :bigint           not null, primary key
#  sales_hook_status :integer          default("disabled")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Config < ApplicationRecord
  enum sales_hook_status: {active: 1, disabled: 0}

  CONFIG = Config.first_or_create

  def self.sales_hook_disabled?
    CONFIG.sales_hook_status == "disabled"
  end

  def self.enable_sales_hook
    CONFIG.update(sales_hook_status: :active)
  end

  def self.disable_sales_hook
    CONFIG.update(sales_hook_status: :disabled)
  end
end

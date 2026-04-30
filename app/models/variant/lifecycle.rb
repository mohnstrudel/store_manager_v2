# frozen_string_literal: true

module Variant::Lifecycle
  extend ActiveSupport::Concern

  def remove_or_deactivate!
    if has_sales_or_purchases?
      update!(deactivated_at: Time.current)
    else
      destroy!
    end
  end
end

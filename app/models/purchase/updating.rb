# frozen_string_literal: true

module Purchase::Updating
  extend ActiveSupport::Concern

  def update_from_form!(attributes:)
    transaction do
      assign_attributes(attributes)
      save!
    end
  end
end

# frozen_string_literal: true

module Sale::Editing
  extend ActiveSupport::Concern

  def create_from_form!(attributes)
    transaction do
      assign_attributes(attributes)
      save!
      link_purchase_items!
    end
  end

  def apply_form_changes!(attributes)
    transaction do
      assign_attributes(attributes.merge(slug: nil))
      status_changed = will_save_change_to_status?
      save!
      sync_status_change_to_shop! if status_changed
    end
  end
end

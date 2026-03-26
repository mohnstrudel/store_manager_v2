# frozen_string_literal: true

module ProductHelper
  def format_relation(relationship, key)
    return "-" if relationship.blank?
    relationship.pluck(key).join(", ")
  end

  def product_row_class(record_id, selected_id:, hoverable: false, **extra_classes)
    class_names(extra_classes.merge(hoverable:, selected: selected_id == record_id))
  end
end

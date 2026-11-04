# frozen_string_literal: true

module Sale::Revisable
  extend ActiveSupport::Concern

  def record(attributes: nil, sale_item_attributes: [], shipping_address: nil, billing_address: nil, **raw_attributes)
    attributes = normalize_form_attributes(attributes, raw_attributes)

    transaction do
      assign_attributes(attributes)
      save!
      address(shipping: shipping_address, billing: billing_address)
      apply_sale_item_attributes(sale_item_attributes)
      link_purchase_items
    end
  end

  def revise(attributes: nil, sale_item_attributes: [], shipping_address: nil, billing_address: nil, **raw_attributes)
    attributes = normalize_form_attributes(attributes, raw_attributes)

    transaction do
      assign_attributes(attributes.merge(slug: nil))
      status_changed = will_save_change_to_status?
      save!
      address(shipping: shipping_address, billing: billing_address)
      apply_sale_item_attributes(sale_item_attributes)
      push_status_to_woo_later if status_changed
      link_purchase_items
    end
  end

  private

  def normalize_form_attributes(attributes, raw_attributes)
    attributes.presence || raw_attributes
  end

  def apply_sale_item_attributes(sale_item_attributes)
    sale_item_attributes.each do |attributes|
      apply_single_sale_item_attributes(attributes)
    end
  end

  def apply_single_sale_item_attributes(attributes)
    if attributes[:destroy]
      destroy_sale_item(attributes[:id])
    elsif attributes[:id].present?
      sale_items.find(attributes[:id]).update!(persisted_sale_item_attributes(attributes))
    elsif blank_sale_item_attributes?(attributes)
      nil
    else
      sale_items.create!(persisted_sale_item_attributes(attributes))
    end
  end

  def destroy_sale_item(id)
    return if id.blank?

    sale_items.find(id).destroy!
  end

  def persisted_sale_item_attributes(attributes)
    attributes.except(:id, :destroy)
  end

  def blank_sale_item_attributes?(attributes)
    persisted_sale_item_attributes(attributes).values.all?(&:blank?)
  end
end

# frozen_string_literal: true

module Product::Editing
  extend ActiveSupport::Concern

  def save_editing!(product_attributes:, editions_attributes:, store_infos_attributes:, purchase_attributes: {}, media_attributes: [], new_media_images: [])
    creating = new_record?

    if creating && purchase_attributes.present?
      purchase = Purchase.new(purchase_attributes.merge(product: self))
    end

    assign_product_attributes(product_attributes)
    assign_editions_attributes(editions_attributes)
    assigned_store_infos = assigned_store_infos_from_attributes(store_infos_attributes)

    valid?
    validate_edition_uniqueness!
    validate_store_infos!(assigned_store_infos)

    if purchase.present? && !purchase.valid?
      errors.add(:purchase, "is invalid")
    end

    raise ActiveRecord::RecordInvalid.new(self) if errors.any?

    transaction do
      save!
      assigned_store_infos.each { |store_info| save_store_info!(store_info) }
      reset_store_info_associations
      editions.each { |edition| save_edition!(edition) }
      update_media_from_form!(media_attributes) unless creating
      add_new_media_from_form!(new_media_images)
      purchase&.product = self
      purchase&.save_editing!
    end
  end

  private

  def assign_product_attributes(attributes)
    assign_attributes(attributes.merge(slug: nil))
    self.full_title = generate_full_title
  end

  def assign_editions_attributes(edition_attributes)
    return if edition_attributes.blank?

    existing_editions = editions.load_target.index_by { |edition| edition.id.to_s }

    edition_attributes.each do |attributes|
      next if destroy_flag?(attributes) && attributes[:id].blank?

      edition = existing_editions[attributes[:id].to_s] || editions.build(product: self)
      assign_edition_attributes(edition, attributes)
    end
  end

  def assigned_store_infos_from_attributes(store_info_attributes)
    return [] if store_info_attributes.blank?

    association(:store_infos).reset
    existing_store_infos = store_infos.load_target.index_by { |store_info| store_info.id.to_s }
    assigned_store_infos = []

    store_info_attributes.each do |attributes|
      next if destroy_flag?(attributes) && attributes[:id].blank?

      store_info = existing_store_infos[attributes[:id].to_s] || store_infos.build(storable: self)
      assign_store_info_attributes(store_info, attributes)
      assigned_store_infos << store_info
    end

    assigned_store_infos
  end

  def reset_store_info_associations
    association(:store_infos).reset if association(:store_infos).loaded?
    association(:shopify_info).reset if association(:shopify_info).loaded?
    association(:woo_info).reset if association(:woo_info).loaded?
  end

  def assign_store_info_attributes(store_info, attributes)
    store_info._destroy = destroy_flag?(attributes)

    if store_info.marked_for_editing_destruction?
      store_info.mark_for_destruction
      return
    end

    store_info.assign_attributes(attributes.except(:id, :destroy))
  end

  def validate_store_infos!(store_infos)
    store_infos.each(&:valid?)
    errors.add(:store_infos, "is invalid") if store_infos.any? { |store_info| store_info.errors.any? }
  end

  def save_store_info!(store_info)
    if store_info.marked_for_destruction?
      store_info.destroy! if store_info.persisted?
      return
    end

    store_info.save! if store_info.new_record? || store_info.changed?
  end

  def validate_edition_uniqueness!
    sku_editions = {}
    combination_editions = {}

    active_editing_editions.each do |edition|
      if edition.sku.present?
        sku_editions[edition.sku] ||= []
        sku_editions[edition.sku] << edition
      end

      combination = edition_combination(edition)
      if combination.present?
        combination_editions[combination] ||= []
        combination_editions[combination] << edition
      end
    end

    add_duplicate_sku_errors(sku_editions)
    add_duplicate_combination_errors(combination_editions)

    errors.add(:editions, "is invalid") if active_editing_editions.any? { |edition| edition.errors.any? }
  end

  def assign_edition_attributes(edition, attributes)
    edition._destroy = destroy_flag?(attributes)
    return if edition.marked_for_editing_destruction?

    edition.assign_attributes(attributes.except(:id, :destroy))
  end

  def save_edition!(edition)
    return if edition.new_record? && edition.marked_for_editing_destruction?

    if edition.marked_for_editing_destruction?
      edition.remove_or_deactivate!
      return
    end

    edition.save! if edition.new_record? || edition.changed?
  end

  def active_editing_editions
    association(:editions).target.reject(&:marked_for_editing_destruction?)
  end

  def add_duplicate_sku_errors(grouped_editions)
    grouped_editions.each_value do |duplicate_editions|
      next if duplicate_editions.one?

      duplicate_editions.each { |edition| edition.errors.add(:sku, "has already been taken") }
    end
  end

  def add_duplicate_combination_errors(grouped_editions)
    grouped_editions.each_value do |duplicate_editions|
      next if duplicate_editions.one?

      duplicate_editions.each { |edition| edition.errors.add(:base, "Combination already exists") }
    end
  end

  def edition_combination(edition)
    combination = [edition.size_id, edition.version_id, edition.color_id]
    combination if combination.any?(&:present?)
  end

  def destroy_flag?(attributes)
    ActiveModel::Type::Boolean.new.cast(attributes[:destroy])
  end
end

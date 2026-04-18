# frozen_string_literal: true

module Product::Editing
  extend ActiveSupport::Concern

  def save_editing!(product_attributes:, editions_attributes:, store_infos_attributes:, purchase_attributes: {}, media_attributes: [], new_media_images: [])
    creating = new_record?
    self.initial_purchase = build_initial_purchase(purchase_attributes, creating)

    assign_product_attributes(product_attributes)
    assign_collection_attributes(:editions, editions_attributes)
    assign_collection_attributes(:store_infos, store_infos_attributes)

    valid?
    validate_edition_uniqueness!
    validate_store_infos!

    errors.add(:initial_purchase, :invalid) if initial_purchase.present? && !initial_purchase.valid?

    raise ActiveRecord::RecordInvalid.new(self) if errors.any?

    transaction do
      save!
      store_infos.each { |store_info| save_store_info!(store_info) }
      editions.each { |edition| save_edition!(edition) }
      update_media_from_form!(media_attributes) unless creating
      add_new_media_from_form!(new_media_images)
      initial_purchase&.product = self
      initial_purchase&.save_editing!
    end
  end

  private

  def build_initial_purchase(purchase_attributes, creating)
    return unless creating && purchase_attributes.present?

    Purchase.new(purchase_attributes.merge(product: self))
  end

  def assign_product_attributes(attributes)
    assign_attributes(attributes.merge(slug: nil))
    self.full_title = generate_full_title
  end

  def assign_collection_attributes(association_name, attributes_list)
    return if attributes_list.blank?

    existing_records = public_send(association_name).load_target.index_by { |record| record.id.to_s }

    attributes_list.each do |attributes|
      next if destroy_flag?(attributes) && attributes[:id].blank?

      record = existing_records[attributes[:id].to_s] || build_associated_record(association_name)
      assign_editable_attributes(record, attributes, association_name)
    end
  end

  def build_associated_record(association_name)
    case association_name
    when :editions
      editions.build(product: self)
    when :store_infos
      store_infos.build(storable: self)
    else
      raise ArgumentError, "Unsupported association: #{association_name}"
    end
  end

  def assign_editable_attributes(record, attributes, association_name)
    record._destroy = destroy_flag?(attributes)

    if record.marked_for_editing_destruction?
      record.mark_for_destruction if association_name == :store_infos
      return
    end

    record.assign_attributes(attributes.except(:id, :destroy))
  end

  def validate_edition_uniqueness!
    sku_editions = {}
    combination_editions = {}
    editing_editions = active_editing_editions

    editing_editions.each do |edition|
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

    errors.add(:editions, :invalid) if editing_editions.any? { |edition| edition.errors.any? }
  end

  def active_editing_editions
    association(:editions).target.reject(&:marked_for_editing_destruction?)
  end

  def edition_combination(edition)
    combination = [edition.size_id, edition.version_id, edition.color_id]
    combination if combination.any?(&:present?)
  end

  def add_duplicate_sku_errors(grouped_editions)
    grouped_editions.each_value do |duplicate_editions|
      next if duplicate_editions.one?

      duplicate_editions.each { |edition| edition.errors.add(:sku, :taken) }
    end
  end

  def add_duplicate_combination_errors(grouped_editions)
    grouped_editions.each_value do |duplicate_editions|
      next if duplicate_editions.one?

      duplicate_editions.each { |edition| edition.errors.add(:base, :combination_exists) }
    end
  end

  def validate_store_infos!
    editing_store_infos = active_editing_store_infos

    editing_store_infos.each(&:valid?)
    errors.add(:store_infos, :invalid) if editing_store_infos.any? { |store_info| store_info.errors.any? }
  end

  def active_editing_store_infos
    association(:store_infos).target.reject(&:marked_for_editing_destruction?)
  end

  def save_store_info!(store_info)
    if store_info.marked_for_destruction?
      store_info.destroy! if store_info.persisted?
      return
    end

    store_info.save! if store_info.new_record? || store_info.changed?
  end

  def save_edition!(edition)
    return if edition.new_record? && edition.marked_for_editing_destruction?

    if edition.marked_for_editing_destruction?
      edition.remove_or_deactivate!
      return
    end

    edition.save! if edition.new_record? || edition.changed?
  end

  def destroy_flag?(attributes)
    ActiveModel::Type::Boolean.new.cast(attributes[:destroy])
  end
end

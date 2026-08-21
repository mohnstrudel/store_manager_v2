# frozen_string_literal: true

module Product::Editing
  extend ActiveSupport::Concern

  def save_editing!(
    product_attributes:,
    variants_attributes:,
    store_infos_attributes:,
    purchase_attributes: {},
    purchase_variant_client_key: nil,
    media_attributes: []
  )
    creating = new_record?
    self.initial_purchase = build_initial_purchase(purchase_attributes, creating)

    assign_product_attributes(product_attributes)
    draft_variants = assign_collection_attributes(:variants, variants_attributes)
    assign_collection_attributes(:store_infos, store_infos_attributes)
    sync_variant_option_ids
    build_base_variant
    ensure_editing_variants_have_skus

    valid?
    validate_variant_uniqueness
    validate_store_infos
    validate_initial_purchase

    raise ActiveRecord::RecordInvalid.new(self) if errors.any?

    transaction do
      save!
      store_infos.each { |store_info| save_store_info(store_info) }
      variants.each { |variant| save_variant(variant) }
      update_media_from_form!(media_attributes)
      save_initial_purchase!(
        draft_variants:,
        variant_client_key: purchase_variant_client_key
      )
    end
  end

  private

  def build_initial_purchase(purchase_attributes, creating)
    return unless creating && purchase_attributes.present?

    # Don't set product: self here — that would add the unsaved purchase to
    # self.purchases via inverse_of, causing spurious autosave validation errors.
    # The product is assigned explicitly in the transaction after save.
    Purchase.new(purchase_attributes)
  end

  def assign_product_attributes(attributes)
    assign_attributes(attributes.merge(slug: nil))
    self.full_title = generate_full_title
  end

  def assign_collection_attributes(association_name, attributes_list)
    return {} if attributes_list.blank?

    existing_records = public_send(association_name).load_target.index_by { |record| record.id.to_s }
    records_by_client_key = {}

    attributes_list.each do |attributes|
      next if destroy_flag?(attributes) && attributes[:id].blank?

      record = existing_records[attributes[:id].to_s] || build_associated_record(association_name)
      assign_editable_attributes(record, attributes, association_name)
      client_key = attributes[:client_key].presence
      records_by_client_key[client_key] = record if client_key
    end

    records_by_client_key
  end

  def build_associated_record(association_name)
    case association_name
    when :variants
      variants.build(product: self)
    when :store_infos
      store_infos.build(storable: self)
    else
      raise ArgumentError, "Unsupported association: #{association_name}"
    end
  end

  def assign_editable_attributes(record, attributes, association_name)
    record._destroy = destroy_flag?(attributes)

    if record.should_be_removed?
      record.mark_for_destruction if association_name == :store_infos
      return
    end

    record.assign_attributes(attributes.except(:id, :client_key, :destroy))
  end

  def validate_variant_uniqueness
    sku_variants = {}
    combination_variants = {}
    editing_variants = active_editing_variants

    editing_variants.each do |variant|
      if variant.sku.present?
        sku_variants[variant.sku] ||= []
        sku_variants[variant.sku] << variant
      end

      combination = variant_combination(variant)
      if combination.present?
        combination_variants[combination] ||= []
        combination_variants[combination] << variant
      end
    end

    add_duplicate_sku_errors(sku_variants)
    add_taken_sku_errors(editing_variants)
    add_duplicate_combination_errors(combination_variants)
    bubble_record_errors("variants", editing_variants)

    errors.add(:variants, :invalid) if editing_variants.any? { |variant| variant.errors.any? }
  end

  def active_editing_variants
    association(:variants).target.reject(&:should_be_removed?)
  end

  def variant_combination(variant)
    combination = [variant.size_id, variant.version_id, variant.color_id]
    combination if combination.any?(&:present?)
  end

  def add_duplicate_sku_errors(grouped_variants)
    grouped_variants.each_value do |duplicate_variants|
      next if duplicate_variants.one?

      duplicate_variants.each { |variant| variant.errors.add(:sku, :taken) }
    end
  end

  def add_taken_sku_errors(editing_variants)
    editing_variants.each do |variant|
      next if variant.errors[:sku].present? || variant.sku.blank?

      conflicting_scope = Variant.where(sku: variant.sku)
      conflicting_scope = conflicting_scope.where.not(id: variant.id) if variant.persisted?
      next unless conflicting_scope.exists?

      variant.errors.add(:sku, :taken)
    end
  end

  def add_duplicate_combination_errors(grouped_variants)
    grouped_variants.each_value do |duplicate_variants|
      next if duplicate_variants.one?

      duplicate_variants.each { |variant| variant.errors.add(:base, :combination_exists) }
    end
  end

  def ensure_editing_variants_have_skus
    active_editing_variants.each do |variant|
      fill_variant_sku(variant, variant.sku.presence || default_base_sku)
    end
  end

  def validate_store_infos
    editing_store_infos = active_editing_store_infos

    editing_store_infos.each(&:valid?)
    bubble_record_errors("store_infos", editing_store_infos)
    errors.add(:store_infos, :invalid) if editing_store_infos.any? { |store_info| store_info.errors.any? }
  end

  def validate_initial_purchase
    return if initial_purchase.blank?

    initial_purchase.valid?
    # product_id and product_or_variant_present errors are irrelevant here —
    # the product is assigned explicitly in the transaction after save.
    relevant_errors = initial_purchase.errors.reject { |e|
      e.attribute == :product_id ||
        (e.attribute == :base && e.message == "must have a product or variant")
    }
    relevant_errors.each do |error|
      nested_attribute = (error.attribute == :base) ? "base" : error.attribute
      errors.add("purchase.0.#{nested_attribute}", error.message)
    end
    errors.add(:initial_purchase, :invalid) if relevant_errors.any?
  end

  def save_initial_purchase!(draft_variants:, variant_client_key:)
    return unless initial_purchase

    variant = draft_variants[variant_client_key]
    unless variant_client_key.present? && variant&.persisted? && !variant.should_be_removed?
      message = variant_client_key.present? ? "is invalid" : "must be selected"
      initial_purchase.errors.add(:variant_client_key, message)
      errors.add("purchase.0.variant_client_key", message)
      errors.add(:initial_purchase, :invalid)
      raise ActiveRecord::RecordInvalid.new(self)
    end

    initial_purchase.product = self
    initial_purchase.variant = variant
    initial_purchase.save_editing!
  rescue ActiveRecord::RecordInvalid => error
    raise if error.record.equal?(self)

    error.record.errors.each do |record_error|
      nested_attribute = (record_error.attribute == :base) ? "base" : record_error.attribute
      errors.add("purchase.0.#{nested_attribute}", record_error.message)
    end
    errors.add(:initial_purchase, :invalid)
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def active_editing_store_infos
    association(:store_infos).target.reject(&:should_be_removed?)
  end

  def save_store_info(store_info)
    if store_info.marked_for_destruction?
      store_info.destroy! if store_info.persisted?
      return
    end

    store_info.save! if store_info.new_record? || store_info.changed?
  end

  def save_variant(variant)
    return if variant.new_record? && variant.should_be_removed?

    if variant.should_be_removed?
      variant.remove_or_deactivate!
      return
    end

    variant.save! if variant.new_record? || variant.changed?
  end

  def destroy_flag?(attributes)
    ActiveModel::Type::Boolean.new.cast(attributes[:destroy])
  end

  def sync_variant_option_ids
    self.size_ids = variant_option_ids(:size_id)
    self.version_ids = variant_option_ids(:version_id)
    self.color_ids = variant_option_ids(:color_id)
  end

  def variant_option_ids(attribute_name)
    active_editing_variants.filter_map { |variant| variant.public_send(attribute_name) }.uniq
  end

  def bubble_record_errors(prefix, records)
    records.each_with_index do |record, index|
      record.errors.each do |error|
        nested_attribute = (error.attribute == :base) ? "base" : error.attribute
        errors.add("#{prefix}.#{index}.#{nested_attribute}", error.message)
      end
    end
  end
end

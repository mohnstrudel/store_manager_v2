# frozen_string_literal: true

module Product::Editing
  extend ActiveSupport::Concern

  def save_editing!(product_attributes:, variants_attributes:, store_infos_attributes:, purchase_attributes: {}, media_attributes: [], new_media_images: [])
    creating = new_record?
    self.initial_purchase = build_initial_purchase(purchase_attributes, creating)

    assign_product_attributes(product_attributes)
    assign_collection_attributes(:variants, variants_attributes)
    assign_collection_attributes(:store_infos, store_infos_attributes)
    build_base_variant
    ensure_editing_variants_have_skus

    valid?
    validate_variant_uniqueness
    validate_store_infos

    errors.add(:initial_purchase, :invalid) if initial_purchase.present? && !initial_purchase.valid?

    raise ActiveRecord::RecordInvalid.new(self) if errors.any?

    transaction do
      save!
      store_infos.each { |store_info| save_store_info(store_info) }
      variants.each { |variant| save_variant(variant) }
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

    record.assign_attributes(attributes.except(:id, :destroy))
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
    errors.add(:store_infos, :invalid) if editing_store_infos.any? { |store_info| store_info.errors.any? }
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
end

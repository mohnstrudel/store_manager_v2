# frozen_string_literal: true

class Product::FormRehydrator
  def initialize(product:, payload:)
    @product = product
    @payload = payload
  end

  def call
    errors = product.errors.dup
    hydrated_product = rehydrated_product
    hydrated_product.errors.copy!(errors)

    reassign_product_attributes(hydrated_product)
    reassign_store_infos(hydrated_product)
    reassign_editions(hydrated_product)

    hydrated_product
  end

  private

  attr_reader :product, :payload

  def rehydrated_product
    return Product.for_details.friendly.find(product.id) if product.persisted?

    product
  end

  def reassign_product_attributes(reloaded_product)
    reloaded_product.assign_attributes(payload.product_attributes)
  end

  def reassign_store_infos(reloaded_product)
    payload.submitted_store_infos.each do |attrs|
      attrs = attrs.with_indifferent_access
      next if destroy_flag?(attrs)

      if attrs[:id].present?
        store_info = reloaded_product.store_infos.to_a.find { |item| item.id.to_s == attrs[:id].to_s }
        store_info&.assign_attributes(attrs.except(:_destroy))
      else
        reloaded_product.store_infos.build(attrs.except(:_destroy))
      end
    end
  end

  def reassign_editions(reloaded_product)
    payload.submitted_editions.each_with_index do |attrs, index|
      attrs = attrs.with_indifferent_access
      next if destroy_flag?(attrs)

      if attrs[:id].present?
        edition = reloaded_product.editions.to_a.find { |item| item.id.to_s == attrs[:id].to_s }
        edition&.assign_attributes(attrs.except(:_destroy))
      else
        edition = reloaded_product.editions.build(attrs.except(:_destroy))
        edition.instance_variable_set(:@_new_edition_index, index)
      end
    end
  end

  def destroy_flag?(attrs)
    ActiveModel::Type::Boolean.new.cast(attrs[:_destroy])
  end
end

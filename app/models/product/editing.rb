# frozen_string_literal: true

module Product::Editing
  extend ActiveSupport::Concern

  def create_from_form!(editions_attributes:, purchase_attributes:)
    transaction do
      save!
      yield self if block_given?
      apply_initial_purchase!(purchase_attributes)
      apply_editions_attributes!(editions_attributes)
    end
  end

  def apply_form_changes!(product_attributes:, editions_attributes:, store_infos_attributes:)
    transaction do
      apply_form_attributes(product_attributes)
      apply_editions_attributes!(editions_attributes)
      save!
      apply_store_infos_attributes!(store_infos_attributes)
      yield self if block_given?
    end
  end

  private

  def apply_form_attributes(attributes)
    assign_attributes(attributes.merge(slug: nil))
    self.full_title = generate_full_title
  end
end

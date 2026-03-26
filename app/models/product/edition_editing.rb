# frozen_string_literal: true

module Product::EditionEditing
  extend ActiveSupport::Concern

  def apply_editions_attributes!(rows)
    return if rows.blank?

    new_editions, existing_editions = rows.partition { |row| row[:id].blank? }

    new_editions.each do |attributes|
      validate_edition_combination!(attributes)
      editions.create!(persisted_edition_attributes(attributes))
    end

    existing_editions.each do |attributes|
      update_existing_edition!(attributes)
    end
  end

  private

  def update_existing_edition!(attributes)
    edition = editions.find(attributes[:id])

    if attributes[:destroy]
      edition.remove_or_deactivate!
      return
    end

    edition.assign_attributes(persisted_edition_attributes(attributes))
    validate_edition_sku_uniqueness!(edition)
    edition.save!
  end

  def persisted_edition_attributes(attributes)
    attributes.except(:id, :destroy)
  end

  def validate_edition_sku_uniqueness!(edition)
    return unless edition.sku_changed?

    existing_edition = Edition.where.not(id: edition.id).find_by(sku: edition.sku)
    return unless existing_edition

    errors.add(:editions, "#{edition.title} sku: has already been taken")
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def validate_edition_combination!(attributes)
    combination = attributes
      .slice(:size_id, :version_id, :color_id)
      .compact_blank

    duplicate = editions.find_by(combination)
    return unless duplicate

    errors.add(:editions, "Combination #{duplicate.title} already exists")
    raise ActiveRecord::RecordInvalid.new(self)
  end
end

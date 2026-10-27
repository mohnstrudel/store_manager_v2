# frozen_string_literal: true

module Sale::Tagging
  extend ActiveSupport::Concern

  STALE_ASSIGNMENT_MESSAGE = "Tags changed since you opened this editor. Reload tags and try again."
  MISSING_SELECTION_MESSAGE = "A selected tag is no longer available. Reload tags and try again."
  UNREADABLE_INPUT_MESSAGE = "Tag selection was not understood. Reload tags and try again."
  NEW_TAGS_UNSUPPORTED_MESSAGE = "New tags can't be created here yet."

  included do
    has_many :sale_taggings, dependent: nil, inverse_of: :sale
    has_many :sales_tags, through: :sale_taggings
  end

  def replace_tags!(ids:, original_ids:, new_tags: [])
    transaction(requires_new: true) do
      lock!
      replace_assignments!(ids: tag_ids_from(ids), original_ids: tag_ids_from(original_ids), new_tags:)
    end
  rescue ActiveRecord::InvalidForeignKey => error
    raise unless error.message.include?("sales_tags")

    reject_tags!(MISSING_SELECTION_MESSAGE)
  end

  private

  def replace_assignments!(ids:, original_ids:, new_tags:)
    reject_tags!(NEW_TAGS_UNSUPPORTED_MESSAGE) if new_tags.present?

    current_ids = sale_taggings.pluck(:sales_tag_id).sort
    reject_tags!(STALE_ASSIGNMENT_MESSAGE) unless original_ids == current_ids
    reject_tags!(MISSING_SELECTION_MESSAGE) unless SalesTag.where(id: ids).count == ids.size

    sale_taggings.where.not(sales_tag_id: ids).delete_all
    added_ids = ids - current_ids
    SaleTagging.insert_all!(added_ids.map { |tag_id| {sale_id: id, sales_tag_id: tag_id} }) if added_ids.any? # rubocop:disable Rails/SkipsModelValidations -- foreign keys own integrity; assignment rows carry no callbacks
  end

  def reject_tags!(message)
    errors.add(:tags, message)
    raise ActiveRecord::RecordInvalid, self
  end

  def tag_ids_from(values)
    return [] if values.nil?

    reject_tags!(UNREADABLE_INPUT_MESSAGE) unless values.is_a?(Array)

    values.map { |value| positive_integer(value) || reject_tags!(UNREADABLE_INPUT_MESSAGE) }.uniq.sort
  end

  def positive_integer(value)
    number = value.is_a?(String) ? Integer(value, 10, exception: false) : value
    number if number.is_a?(Integer) && number.positive?
  end
end

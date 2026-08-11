# frozen_string_literal: true

class Media::LegacyAttachmentBackfill
  LEGACY_NAME = "images"
  MODELS = [Product, Warehouse].freeze

  Result = Data.define(:created_count, :owners_backfilled)

  def self.call
    new.call
  end

  def call
    created_count = 0
    owners_backfilled = 0

    MODELS.each do |model|
      ids = gap_owner_ids(model)
      next if ids.empty?

      model.where(id: ids).find_each do |owner|
        created = backfill_owner(owner)
        next if created.zero?

        created_count += created
        owners_backfilled += 1
      end
    end

    Result.new(created_count:, owners_backfilled:)
  end

  private

  def gap_owner_ids(model)
    covered_owner_ids = Media.joins(:image_attachment).where(mediaable_type: model.name).select(:mediaable_id)

    ActiveStorage::Attachment
      .where(name: LEGACY_NAME, record_type: model.name)
      .where.not(record_id: covered_owner_ids)
      .distinct
      .pluck(:record_id)
  end

  def backfill_owner(owner)
    legacy_attachments = ActiveStorage::Attachment
      .where(name: LEGACY_NAME, record_type: owner.class.name, record_id: owner.id)
      .includes(:blob)
      .order(:id)

    created = 0
    legacy_attachments.each_with_index do |attachment, index|
      next if attachment.blob.blank?

      media = owner.media.build(position: index)
      media.image.attach(attachment.blob)
      media.save!
      created += 1
    end
    created
  end
end

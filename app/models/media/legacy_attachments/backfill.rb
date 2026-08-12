# frozen_string_literal: true

class Media::LegacyAttachments::Backfill
  Result = Data.define(:created_count, :owners_backfilled)

  def self.apply!
    new.apply!
  end

  def apply!
    created_count = 0
    owners_backfilled = 0

    Media::LegacyAttachments::OWNER_CLASSES.each do |owner_class|
      owners_with_legacy_attachments(owner_class).find_each do |owner|
        created = backfill_owner!(owner)
        next if created.zero?

        created_count += created
        owners_backfilled += 1
      end
    end

    Result.new(created_count:, owners_backfilled:)
  end

  private

  def owners_with_legacy_attachments(owner_class)
    owner_ids = legacy_attachments(owner_class).select(:record_id)

    owner_class.where(id: owner_ids)
  end

  def backfill_owner!(owner)
    created_count = 0

    owner.with_lock do
      attachments = legacy_attachments(owner.class)
        .where(record_id: owner.id)
        .includes(:blob)
        .order(:id)
        .to_a
      media_blob_ids = media_blob_ids_for(owner).to_set
      legacy_blob_ids = attachments.map(&:blob_id).to_set

      next if unrelated_media_exists?(media_blob_ids, legacy_blob_ids)

      attachments.each_with_index do |attachment, position|
        next if media_blob_ids.include?(attachment.blob_id)

        media = owner.media.build(position:)
        media.image.attach(attachment.blob)
        media.save!
        media_blob_ids.add(attachment.blob_id)
        created_count += 1
      end
    end

    created_count
  end

  def media_blob_ids_for(owner)
    media_ids = owner.media.select(:id)

    ActiveStorage::Attachment
      .where(name: "image", record_type: "Media", record_id: media_ids)
      .distinct
      .pluck(:blob_id)
  end

  def unrelated_media_exists?(media_blob_ids, legacy_blob_ids)
    media_blob_ids.any? && media_blob_ids.intersection(legacy_blob_ids).empty?
  end

  def legacy_attachments(owner_class)
    Media::LegacyAttachments.for_owner_class(owner_class)
  end
end

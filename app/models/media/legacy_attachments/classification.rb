# frozen_string_literal: true

class Media::LegacyAttachments::Classification
  DELETABLE_RELATIONS = %i[retained releasing orphaned_retained orphaned_releasing].freeze

  attr_reader :owner_class

  def initialize(owner_class)
    @owner_class = owner_class
  end

  def blocked
    @blocked ||= live
      .where.not(record_id: owners_with_media_ids)
      .or(live.where(record_id: partial_owner_ids))
  end

  def retained
    @retained ||= covered.where(blob_id: retained_blob_ids)
  end

  def releasing
    @releasing ||= releasing_all.where(record_id: recoverable_owner_ids)
  end

  def unrecoverable
    @unrecoverable ||= releasing_all.where.not(record_id: recoverable_owner_ids)
  end

  def orphaned_retained
    @orphaned_retained ||= orphaned.where(blob_id: retained_blob_ids)
  end

  def orphaned_releasing
    @orphaned_releasing ||= orphaned.where.not(blob_id: retained_blob_ids)
  end

  def deletable
    DELETABLE_RELATIONS.map { |relation_name| public_send(relation_name) }.reduce(&:or)
  end

  def deletable_without_purge
    retained.or(orphaned_retained)
  end

  def deletable_with_purge
    releasing.or(orphaned_releasing)
  end

  private

  def legacy
    @legacy ||= Media::LegacyAttachments.for_owner_class(owner_class)
  end

  def live
    @live ||= legacy.where(record_id: owner_class.select(:id))
  end

  def orphaned
    @orphaned ||= legacy.where.not(record_id: owner_class.select(:id))
  end

  def covered
    @covered ||= live.where.not(record_id: blocked.select(:record_id))
  end

  def releasing_all
    @releasing_all ||= covered.where.not(blob_id: retained_blob_ids)
  end

  def owners_with_media_ids
    Media.joins(:image_attachment)
      .where(mediaable_type: owner_class.name)
      .select(:mediaable_id)
  end

  def matched
    @matched ||= legacy.joins(media_match_joins).distinct
  end

  def partial_owner_ids
    live
      .where(record_id: matched.select(:record_id))
      .where.not(id: matched.select(:id))
      .select(:record_id)
  end

  def retained_blob_ids
    ActiveStorage::Attachment
      .where.not(name: Media::LegacyAttachments::NAME)
      .select(:blob_id)
  end

  def recoverable_owner_ids
    StoreInfo.shopify
      .where(storable_type: owner_class.name)
      .where.not(store_id: [nil, ""])
      .select(:storable_id)
  end

  def media_match_joins
    ActiveRecord::Base.sanitize_sql_array([
      <<~SQL.squish,
        INNER JOIN media legacy_attachment_media
          ON legacy_attachment_media.mediaable_type = ?
          AND legacy_attachment_media.mediaable_id = active_storage_attachments.record_id
        INNER JOIN active_storage_attachments legacy_attachment_media_images
          ON legacy_attachment_media_images.record_type = 'Media'
          AND legacy_attachment_media_images.record_id = legacy_attachment_media.id
          AND legacy_attachment_media_images.name = 'image'
          AND legacy_attachment_media_images.blob_id = active_storage_attachments.blob_id
      SQL
      owner_class.name
    ])
  end
end

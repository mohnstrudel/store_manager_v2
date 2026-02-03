# frozen_string_literal: true

class MigrateImagesToMedia < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL.squish
        WITH numbered_attachments AS (
          SELECT
            a.id AS old_attachment_id,
            a.record_type,
            a.record_id,
            a.blob_id,
            ROW_NUMBER() OVER (PARTITION BY a.record_type, a.record_id ORDER BY a.id) AS position
          FROM active_storage_attachments a
          WHERE a.name = 'images'
            AND a.record_type IN ('Product', 'PurchaseItem', 'Warehouse')
            AND NOT EXISTS (
              SELECT 1 FROM media m
              WHERE m.mediaable_type = a.record_type
                AND m.mediaable_id = a.record_id
            )
        ),
        inserted_media AS (
          INSERT INTO media (mediaable_type, mediaable_id, position, alt, created_at, updated_at)
          SELECT
            record_type,
            record_id,
            position,
            '',
            NOW(),
            NOW()
          FROM numbered_attachments
          ON CONFLICT DO NOTHING
          RETURNING id, mediaable_type, mediaable_id, position
        ),
        numbered_media AS (
          SELECT
            inserted_media.id AS media_id,
            mediaable_type,
            mediaable_id,
            inserted_media.position,
            ROW_NUMBER() OVER (PARTITION BY mediaable_type, mediaable_id ORDER BY id) AS rn
          FROM inserted_media
        ),
        numbered_attachments_with_rn AS (
          SELECT
            old_attachment_id,
            record_type,
            record_id,
            blob_id,
            position,
            ROW_NUMBER() OVER (PARTITION BY record_type, record_id ORDER BY old_attachment_id) AS rn
          FROM numbered_attachments
        ),
        new_attachment_ids AS (
          SELECT
            (SELECT COALESCE(MAX(id), 0) FROM active_storage_attachments) + ROW_NUMBER() OVER (ORDER BY old_attachment_id) AS new_attachment_id,
            old_attachment_id,
            blob_id
          FROM numbered_attachments_with_rn
        ),
        inserted_attachments AS (
          INSERT INTO active_storage_attachments (id, record_type, record_id, name, blob_id, created_at)
          SELECT
            new_attachment_id,
            'Media',
            numbered_media.media_id,
            'image',
            numbered_attachments_with_rn.blob_id,
            NOW()
          FROM numbered_attachments_with_rn
          JOIN numbered_media
            ON numbered_media.mediaable_type = numbered_attachments_with_rn.record_type
            AND numbered_media.mediaable_id = numbered_attachments_with_rn.record_id
            AND numbered_media.rn = numbered_attachments_with_rn.rn
          JOIN new_attachment_ids
            ON new_attachment_ids.old_attachment_id = numbered_attachments_with_rn.old_attachment_id
          ON CONFLICT (id) DO NOTHING
          RETURNING id
        )
        SELECT 1
      SQL
    end
  end

  def down
    safety_assured do
      execute "DELETE FROM media WHERE mediaable_type IN ('Product', 'PurchaseItem', 'Warehouse')"
    end
  end
end

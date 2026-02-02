class MigrateImagesToMedia < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      WITH numbered_attachments AS (
        SELECT
          id AS attachment_id,
          record_type,
          record_id,
          ROW_NUMBER() OVER (PARTITION BY record_type, record_id ORDER BY id) AS position
        FROM active_storage_attachments
        WHERE name = 'images'
          AND record_type IN ('Product', 'PurchaseItem', 'Warehouse')
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
      )
      UPDATE active_storage_attachments
      SET record_type = 'Media',
          record_id = inserted_media.id,
          name = 'image'
      FROM numbered_attachments
      JOIN inserted_media
        ON inserted_media.mediaable_type = numbered_attachments.record_type
        AND inserted_media.mediaable_id = numbered_attachments.record_id
        AND inserted_media.position = numbered_attachments.position
      WHERE active_storage_attachments.id = numbered_attachments.attachment_id
    SQL
  end

  def down
    execute "DELETE FROM media WHERE mediaable_type IN ('Product', 'PurchaseItem', 'Warehouse')"
  end
end

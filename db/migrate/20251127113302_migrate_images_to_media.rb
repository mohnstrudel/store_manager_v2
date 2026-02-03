# frozen_string_literal: true

class MigrateImagesToMedia < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  BATCH_SIZE = 500

  def up
    safety_assured do
      models_with_images = [Product, PurchaseItem, Warehouse]

      models_with_images.each do |model_class|
        model_class
          .where.associated(:images)
          .in_batches(of: BATCH_SIZE) do |batch|
            records = batch
              .preload(images_attachments: :blob)
              .to_a

            ActiveRecord::Base.transaction(requires_new: true) do
              records.each do |record|
                next if record.images.none?

                record.images.each do |attachment|
                  next if attachment.blob.blank?

                  media = nil

                  ActiveRecord::Base.transaction(requires_new: true) do
                    media = record.media.build

                    media.image.attach(
                      blob_id: attachment.blob_id,
                      filename: attachment.filename,
                      content_type: attachment.content_type
                    )

                    media.save!
                  end
                rescue => e
                  say "Failed to migrate image for #{record.class}##{record.id} " \
                      "(attachment #{attachment.id}): #{e.message}", true
                end
              end
            end
        end

        say "Finished migrating #{model_class.name}"
      end
    end
  end

  def down
    safety_assured do
      execute "DELETE FROM media WHERE mediaable_type IN ('Product', 'PurchaseItem', 'Warehouse')"
    end
  end
end

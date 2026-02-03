# frozen_string_literal: true

class MigrateImagesToMedia < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  BATCH_SIZE = 100
  SLEEP_SECONDS = 0.4

  MODELS = [Product, PurchaseItem, Warehouse].freeze

  def up
    safety_assured do
      MODELS.each do |klass|
        klass
          .joins("INNER JOIN active_storage_attachments asa
                    ON asa.record_type = '#{klass.base_class.name}'
                    AND asa.record_id  = #{klass.table_name}.id
                    AND asa.name       = 'images'")
          .distinct
          .in_batches.of(BATCH_SIZE) do |batch|
          batch.find_each do |record|
            next if record.media.joins(:image_attachment).exists?

            record.transaction(requires_new: true) do
              record.images.each_with_index do |img, index|
                next if img.blob.nil?

                media = record.media.build(
                  position: index + 1,
                  alt: "",
                  created_at: Time.current,
                  updated_at: Time.current
                )

                media.image.attach(img.blob)

                media.save!
              end
            end

            GC.start(full_mark: true, immediate_sweep: true) if rand < 0.1

            sleep(SLEEP_SECONDS)
          end
        end
      end
    end
  end

  def down
    safety_assured do
      Media.where(mediaable_type: MODELS.map(&:name)).delete_all
    end
  end
end

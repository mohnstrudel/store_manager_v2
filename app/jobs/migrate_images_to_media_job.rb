# frozen_string_literal: true

class MigrateImagesToMediaJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform
    models_with_images = [Product, PurchaseItem, Warehouse]

    models_with_images.each do |model|
      model
        .joins(:images_attachments)
        .distinct
        .in_batches(of: BATCH_SIZE) do |batch_relation|
          batch_relation
            .preload(images_attachments: :blob)
            .find_each do |record|
              process_record(record)
            end
        end
    end
  end

  private

  def process_record(record)
    return if record.images.none?

    record.images.each do |img|
      next if img.blob.blank?

      media = record.media.build
      media.image.attach(img.blob)
      media.save!

      %i[preview thumb nano].each { |v|
        begin
          media.image.variant(v).processed
        rescue
          nil
        end
      }
    end
  end
end

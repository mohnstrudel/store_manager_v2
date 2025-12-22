class MigrateImagesToMedia < ActiveRecord::Migration[8.1]
  def up
    models_with_images = [Product, PurchaseItem, Warehouse]

    models_with_images.each do |model_class|
      model_class.find_each do |record|
        record.images.each do |img|
          media = record.media.create
          media.image.attach(img.blob)
        end
      end
    end
  end

  def down
    Media.delete_all
  end
end

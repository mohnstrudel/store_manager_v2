# frozen_string_literal: true

module Media::LegacyAttachments
  NAME = "images"
  OWNER_CLASSES = [Product, PurchaseItem, Warehouse].freeze
  OWNER_CLASSES_BY_NAME = OWNER_CLASSES.index_by(&:name).freeze

  def self.for_owner_class(owner_class)
    ActiveStorage::Attachment.where(name: NAME, record_type: owner_class.name)
  end

  def self.owner_class_for!(name)
    OWNER_CLASSES_BY_NAME.fetch(name)
  rescue KeyError
    raise ArgumentError, "Unsupported legacy attachment owner type: #{name.inspect}"
  end
end

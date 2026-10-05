# frozen_string_literal: true

FactoryBot.define do
  factory :blob, class: "ActiveStorage::Blob" do
    skip_create

    key { "test-key-#{SecureRandom.uuid}" }
    filename { "test.jpg" }
    content_type { "image/jpeg" }
    byte_size { 1024 }
    checksum { Base64.strict_encode64(Digest::MD5.digest("test content")) }

    initialize_with do
      ActiveStorage::Blob.create!(
        key:,
        filename:,
        content_type:,
        byte_size:,
        checksum:
      )
    end
  end

  factory :attachment, class: "ActiveStorage::Attachment" do
    name { "images" }
    record_type { "Product" }
    record_id { 1 }
    blob

    transient do
      record { nil }
    end

    to_create do |attachment, evaluator|
      if evaluator.record
        attachment.record_type = evaluator.record.class.to_s
        attachment.record_id = evaluator.record.id
      end
      attachment.save!(validate: false)
    end

    initialize_with do
      ActiveStorage::Attachment.new(
        name: "images",
        record_type: "Product",
        record_id: 1,
        blob_id: blob.id
      )
    end
  end
end

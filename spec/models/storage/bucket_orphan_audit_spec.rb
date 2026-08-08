# frozen_string_literal: true

require "rails_helper"

RSpec.describe Storage::BucketOrphanAudit do
  FakeBucketObject = Struct.new(:key, :size)

  FakePaginatedBucket = Struct.new(:pages) do
    def objects
      Enumerator.new do |yielder|
        pages.each { |page| page.each { |object| yielder << object } }
      end
    end
  end

  def write_stray_file(content: "stray bytes")
    service = ActiveStorage::Blob.service
    key = SecureRandom.base36(28)
    service.upload(key, StringIO.new(content))
    FakeBucketObject.new(key, content.bytesize)
  end

  describe "#call" do
    it "reports bucket keys with no matching blob row, with count and total bytes" do
      known_blob = create(:media, :for_product).image.blob
      stray = write_stray_file

      bucket = FakePaginatedBucket.new([[
        FakeBucketObject.new(known_blob.key, known_blob.byte_size),
        stray
      ]])

      result = described_class.call(bucket:)

      expect(result.orphan_keys).to eq([stray.key])
      expect(result.count).to eq(1)
      expect(result.total_bytes).to eq(stray.size)
    end

    it "never reports a key that has a matching blob row" do
      known_blob = create(:media, :for_product).image.blob
      bucket = FakePaginatedBucket.new([[FakeBucketObject.new(known_blob.key, known_blob.byte_size)]])

      result = described_class.call(bucket:)

      expect(result.orphan_keys).to be_empty
      expect(result.count).to eq(0)
    end

    it "covers every page, not just the first" do
      known_blob = create(:media, :for_product).image.blob
      stray_a = write_stray_file(content: "first page orphan")
      stray_b = write_stray_file(content: "second page orphan")

      first_page = [FakeBucketObject.new(known_blob.key, known_blob.byte_size), stray_a]
      second_page = [stray_b]
      bucket = FakePaginatedBucket.new([first_page, second_page])

      result = described_class.call(bucket:)

      expect(result.orphan_keys).to contain_exactly(stray_a.key, stray_b.key)
      expect(result.count).to eq(2)
      expect(result.total_bytes).to eq(stray_a.size + stray_b.size)
    end
  end
end

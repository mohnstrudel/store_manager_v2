# frozen_string_literal: true

module Storage
  class LegacyImageAttachmentAudit
    LEGACY_NAME = "images"

    Result = Data.define(
      :retained_ids,
      :releasing_ids,
      :releasing_unrecoverable_ids,
      :orphaned_owner_ids,
      :blocked_ids,
      :blocked_owners,
      :releasing_bytes,
      :total
    ) do
      def deletable_ids(allow_unrecoverable: false)
        ids = retained_ids + releasing_ids + orphaned_owner_ids
        ids += releasing_unrecoverable_ids if allow_unrecoverable
        ids
      end

      def released_ids(allow_unrecoverable: false)
        ids = releasing_ids + orphaned_owner_ids
        ids += releasing_unrecoverable_ids if allow_unrecoverable
        ids
      end

      def blocked?
        blocked_ids.any?
      end
    end

    def self.call(name: LEGACY_NAME)
      new(name:).call
    end

    def initialize(name: LEGACY_NAME)
      @name = name
    end

    def call
      rows = ActiveStorage::Attachment
        .where(name: name)
        .joins(:blob)
        .pluck(:id, :record_type, :record_id, :blob_id, "active_storage_blobs.byte_size")

      empty_result = Result.new(
        retained_ids: [], releasing_ids: [], releasing_unrecoverable_ids: [],
        orphaned_owner_ids: [], blocked_ids: [], blocked_owners: [],
        releasing_bytes: 0, total: 0
      )
      return empty_result if rows.empty?

      rows_by_type = rows.group_by { |row| row[1] }

      retained_blob_ids = ActiveStorage::Attachment
        .where.not(name: name)
        .where(blob_id: rows.map { |row| row[3] }.uniq)
        .distinct
        .pluck(:blob_id)
        .to_set

      covered_owner_keys = Media.joins(:image_attachment)
        .distinct
        .pluck(:mediaable_type, :mediaable_id)
        .to_set

      live_ids_by_type = rows_by_type.each_with_object({}) { |(type, type_rows), memo|
        memo[type] = type.constantize.where(id: type_rows.map { |row| row[2] }).pluck(:id).to_set
      }

      shopify_linked_ids_by_type = rows_by_type.each_with_object({}) { |(type, type_rows), memo|
        memo[type] = StoreInfo.shopify
          .where(storable_type: type, storable_id: type_rows.map { |row| row[2] })
          .where.not(store_id: [nil, ""])
          .distinct
          .pluck(:storable_id)
          .to_set
      }

      retained_ids = []
      releasing_ids = []
      releasing_unrecoverable_ids = []
      orphaned_owner_ids = []
      blocked_ids = []
      blocked_owners = Set.new
      releasing_bytes = 0

      rows.each do |id, record_type, record_id, blob_id, byte_size|
        unless live_ids_by_type[record_type].include?(record_id)
          orphaned_owner_ids << id
          next
        end

        unless covered_owner_keys.include?([record_type, record_id])
          blocked_ids << id
          blocked_owners << [record_type, record_id]
          next
        end

        if retained_blob_ids.include?(blob_id)
          retained_ids << id
          next
        end

        releasing_bytes += byte_size.to_i
        if shopify_linked_ids_by_type[record_type].include?(record_id)
          releasing_ids << id
        else
          releasing_unrecoverable_ids << id
        end
      end

      Result.new(
        retained_ids:,
        releasing_ids:,
        releasing_unrecoverable_ids:,
        orphaned_owner_ids:,
        blocked_ids:,
        blocked_owners: blocked_owners.to_a,
        releasing_bytes:,
        total: rows.size
      )
    end

    private

    attr_reader :name
  end
end

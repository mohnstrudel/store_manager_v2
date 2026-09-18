# frozen_string_literal: true

class Variant::AssignmentContractionGate
  IntegrityError = Class.new(StandardError)

  def self.verify!
    new.verify!
  end

  def initialize(integrity: Variant::AssignmentIntegrity.new)
    @integrity = integrity
  end

  def verify!
    snapshot = counts
    return snapshot if snapshot.values.all?(&:zero?)

    details = snapshot.map { |name, count| "#{name}=#{count}" }.join(" ")
    raise IntegrityError, "Variant assignment contraction refused: #{details}"
  end

  def counts
    integrity.counts.merge(
      purchase_item_purchase_identity:
        integrity.purchase_item_purchase_identity_mismatches.count,
      base_models: base_model_issue_count,
      base_activation: base_activation_issue_count,
      duplicate_variant_store_identity:
        duplicate_variant_store_identity_count
    )
  end

  private

  attr_reader :integrity

  def base_model_issue_count
    Product
      .left_joins(:variants)
      .group(:id)
      .having(<<~SQL.squish)
        COUNT(variants.id) FILTER (
          WHERE variants.size_id IS NULL
            AND variants.version_id IS NULL
            AND variants.color_id IS NULL
        ) <> 1
      SQL
      .count
      .size
  end

  def base_activation_issue_count
    Product
      .joins(:variants)
      .group(:id)
      .having(<<~SQL.squish)
        (
          COUNT(variants.id) FILTER (
            WHERE variants.size_id IS NULL
              AND variants.version_id IS NULL
              AND variants.color_id IS NULL
              AND variants.deactivated_at IS NULL
          ) = 1
          AND
          COUNT(variants.id) FILTER (
            WHERE (
              variants.size_id IS NOT NULL
              OR variants.version_id IS NOT NULL
              OR variants.color_id IS NOT NULL
            )
            AND variants.deactivated_at IS NULL
          ) > 0
        )
        OR
        (
          COUNT(variants.id) FILTER (
            WHERE variants.size_id IS NULL
              AND variants.version_id IS NULL
              AND variants.color_id IS NULL
              AND variants.deactivated_at IS NULL
          ) = 0
          AND
          COUNT(variants.id) FILTER (
            WHERE (
              variants.size_id IS NOT NULL
              OR variants.version_id IS NOT NULL
              OR variants.color_id IS NOT NULL
            )
            AND variants.deactivated_at IS NULL
          ) = 0
        )
      SQL
      .count
      .size
  end

  def duplicate_variant_store_identity_count
    StoreInfo
      .where(storable_type: "Variant")
      .where.not(store_id: nil)
      .where("BTRIM(store_infos.store_id) <> ''")
      .group(:store_name, :store_id)
      .having("COUNT(*) > 1")
      .count
      .size
  end
end

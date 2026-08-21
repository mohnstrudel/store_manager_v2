# frozen_string_literal: true

class Variant::AssignmentBackfill
  PHASES = %i[
    sync_base_activation
    reconcile_shopify_identity
    repair_purchases
    repair_sale_items
    backfill_purchase_item_identity
    repair_purchase_item_links
    audit
  ].freeze

  Result = Data.define(
    :mode,
    :before_counts,
    :after_counts,
    :phase_counts,
    :failures
  )
  Candidate = Data.define(:id, :record, :details)

  def self.call(env: ENV, output: $stdout)
    new(
      apply: env["APPLY"] == "1",
      output:,
      resume_from: env["RESUME_FROM"].presence,
      after_id: env["AFTER_ID"].presence
    ).call
  end

  def initialize(
    apply: false,
    output: $stdout,
    resume_from: nil,
    after_id: nil,
    batch_size: 100,
    integrity: Variant::AssignmentIntegrity.new,
    repair: Variant::AssignmentRepair.new
  )
    @apply = apply
    @output = output
    @resume_from = resume_from&.to_sym
    @after_id = after_id&.to_i
    @batch_size = batch_size
    @integrity = integrity
    @repair = repair
    @phase_counts = {}
    @failures = []
    @halted = false
    validate_resume_options!
  end

  def call
    before_counts = counts_snapshot
    log "VARIANT_ASSIGNMENT_BACKFILL mode=#{mode}"
    log_counts("before", before_counts)
    log "RESUME phase=#{resume_from} after_id=#{after_id}" if resume_from

    runnable_phases.each do |phase|
      send(:"run_#{phase}")
      break if halted?
    end

    after_counts = counts_snapshot
    log_counts("after", after_counts)
    Result.new(
      mode:,
      before_counts:,
      after_counts:,
      phase_counts:,
      failures:
    )
  end

  private

  attr_reader :after_id,
    :batch_size,
    :failures,
    :integrity,
    :output,
    :phase_counts,
    :repair,
    :resume_from

  def apply?
    @apply
  end

  def halted?
    @halted
  end

  def mode
    apply? ? "apply" : "dry-run"
  end

  def validate_resume_options!
    return if resume_from.blank? && after_id.blank?
    raise ArgumentError, "RESUME_FROM is required with AFTER_ID" if resume_from.blank?
    raise ArgumentError, "Unknown resume phase: #{resume_from}" unless PHASES.include?(resume_from)
  end

  def runnable_phases
    return PHASES unless resume_from

    PHASES.drop_while { |phase| phase != resume_from }
  end

  def run_sync_base_activation
    candidates = Product.includes(:variants).order(:id).filter_map do |product|
      next unless base_activation_issue?(product)

      Candidate.new(
        id: product.id,
        record: product,
        details: {reason: :base_activation_mismatch}
      )
    end
    process_candidates(:sync_base_activation, candidates) do |candidate|
      Product.find(candidate.id).synchronize_variant_availability!
    end
  end

  def run_reconcile_shopify_identity
    candidates = duplicate_shopify_store_ids.filter_map do |store_id|
      infos = duplicate_shopify_infos(store_id).order(:id).to_a
      canonical_info = canonical_shopify_info(infos)
      Candidate.new(
        id: infos.first.id,
        record: canonical_info,
        details: {
          reason: canonical_info ? :unique_pull_provenance : :ambiguous_pull_provenance,
          store_id:,
          store_info_ids: infos.pluck(:id)
        }
      )
    end
    process_candidates(
      :reconcile_shopify_identity,
      candidates,
      unresolved: ->(candidate) { candidate.record.blank? }
    ) do |candidate|
      repair.reconcile_duplicate_shopify_identity!(
        store_id: candidate.details.fetch(:store_id),
        canonical_store_info_id: candidate.record.id
      )
    end
  end

  def run_repair_purchases
    candidates = integrity.broken_purchases.order(:id).map do |purchase|
      product, variant, reason = deterministic_purchase_identity(purchase)
      Candidate.new(
        id: purchase.id,
        record: variant,
        details: {
          reason:,
          product_id: product&.id,
          variant_id: variant&.id
        }
      )
    end
    process_candidates(
      :repair_purchases,
      candidates,
      unresolved: ->(candidate) { candidate.record.blank? }
    ) do |candidate|
      repair.repair_purchase!(
        purchase_id: candidate.id,
        variant_id: candidate.details.fetch(:variant_id)
      )
    end
  end

  def run_repair_sale_items
    candidates = integrity.broken_sale_items.order(:id).map do |sale_item|
      product, variant, reason = deterministic_sale_item_identity(sale_item)
      Candidate.new(
        id: sale_item.id,
        record: variant,
        details: {
          reason:,
          product_id: product&.id,
          variant_id: variant&.id
        }
      )
    end
    process_candidates(
      :repair_sale_items,
      candidates,
      unresolved: ->(candidate) { candidate.record.blank? }
    ) do |candidate|
      repair.repair_sale_item!(
        sale_item_id: candidate.id,
        product_id: candidate.details.fetch(:product_id),
        variant_id: candidate.details.fetch(:variant_id)
      )
    end
  end

  def run_backfill_purchase_item_identity
    candidates = integrity
      .purchase_item_purchase_identity_mismatches
      .order(:id)
      .map do |purchase_item|
        Candidate.new(
          id: purchase_item.id,
          record: purchase_item,
          details: {reason: :purchase_identity_mismatch}
        )
      end
    process_candidates(:backfill_purchase_item_identity, candidates) do |candidate|
      repair.repair_purchase_item_identity!(purchase_item_id: candidate.id)
    end
  end

  def run_repair_purchase_item_links
    candidates = integrity.incompatible_purchase_item_links.order(:id).map do |purchase_item|
      Candidate.new(
        id: purchase_item.id,
        record: purchase_item,
        details: {reason: :incompatible_link}
      )
    end
    process_candidates(:repair_purchase_item_links, candidates) do |candidate|
      repair.repair_purchase_item_link!(purchase_item_id: candidate.id)
    end
  end

  def run_audit
    counts = counts_snapshot
    phase_counts[:audit] = counts.merge(
      scanned: counts.values.sum,
      planned: 0,
      repaired: 0,
      unresolved: unresolved_integrity_count(counts),
      failures: 0
    )
    log_counts("audit", counts)
    log_checkpoint(:audit, nil, phase_counts.fetch(:audit))
  end

  def process_candidates(phase, candidates, unresolved: ->(_candidate) { false })
    candidates = resume_candidates(phase, candidates).sort_by(&:id)
    counts = {
      scanned: 0,
      planned: 0,
      repaired: 0,
      unresolved: 0,
      failures: 0,
      reasons: Hash.new(0)
    }
    phase_counts[phase] = counts
    last_completed_id = nil

    candidates.each_slice(batch_size) do |batch|
      batch.each do |candidate|
        counts[:scanned] += 1
        counts[:reasons][candidate.details[:reason]] += 1
        if unresolved.call(candidate)
          counts[:unresolved] += 1
          log_unresolved(phase, candidate)
          last_completed_id = candidate.id
          next
        end

        counts[:planned] += 1
        if apply?
          result = yield(candidate)
          counts[:repaired] += 1 unless result == :noop || reconciliation_noop?(result)
        end
        last_completed_id = candidate.id
      rescue => error
        counts[:failures] += 1
        failures << {
          phase:,
          id: candidate.id,
          error_class: error.class.name,
          message: error.message
        }
        log "FAILURE phase=#{phase} id=#{candidate.id} class=#{error.class.name} message=#{error.message.inspect}"
        @halted = true
        log(
          "HALTED phase=#{phase} failed_id=#{candidate.id} " \
            "resume_after_id=#{last_completed_id}"
        )
        break
      end
      log_checkpoint(phase, last_completed_id, counts)
      break if halted?
    end

    log_checkpoint(phase, nil, counts) if candidates.empty?
  end

  def reconciliation_noop?(result)
    return false unless result.is_a?(Variant::AssignmentRepair::ShopifyIdentityReconciliation)

    result.removed_store_info_count.zero? &&
      result.repaired_purchase_count.zero? &&
      result.repaired_sale_item_count.zero?
  end

  def resume_candidates(phase, candidates)
    return candidates unless phase == resume_from && after_id

    candidates.select { |candidate| candidate.id > after_id }
  end

  def deterministic_purchase_identity(purchase)
    product = purchase.product || purchase.variant&.product
    return [nil, nil, :missing_product] unless product
    return [product, nil, :ambiguous_option_product] if product.variants.real.exists?

    [product, product.base_variant, :base_only_product]
  end

  def deterministic_sale_item_identity(sale_item)
    origin = sale_item.origin_sale_item
    if origin&.product && origin.variant&.product_id == origin.product_id
      return [origin.product, origin.variant, :origin_installment]
    end

    product = sale_item.product || sale_item.variant&.product
    return [nil, nil, :missing_product] unless product

    real_variants = product.variants.real.to_a
    return [product, product.base_variant, :base_only_product] if real_variants.empty?
    return [product, real_variants.first, :single_real_variant] if real_variants.one?

    [product, nil, :ambiguous_option_product]
  end

  def counts_snapshot
    integrity.counts.merge(
      purchase_item_purchase_identity:
        integrity.purchase_item_purchase_identity_mismatches.count,
      base_activation: base_activation_issue_count,
      duplicate_shopify_identity: duplicate_shopify_store_ids.size
    )
  end

  def base_activation_issue_count
    Product.includes(:variants).count { |product| base_activation_issue?(product) }
  end

  def base_activation_issue?(product)
    base_variants = product.variants.select(&:base_model?)
    return false unless base_variants.one?

    base = base_variants.first
    active_real_variant = product.variants.any? { |variant| !variant.base_model? && !variant.deactivated? }
    base.deactivated? != active_real_variant
  end

  def duplicate_shopify_store_ids
    StoreInfo
      .shopify
      .where(storable_type: "Variant")
      .where.not(store_id: [nil, ""])
      .group(:store_id)
      .having("COUNT(*) > 1")
      .order(:store_id)
      .pluck(:store_id)
  end

  def duplicate_shopify_infos(store_id)
    StoreInfo.shopify.where(storable_type: "Variant", store_id:)
  end

  def canonical_shopify_info(infos)
    with_pull_provenance = infos.select do |info|
      info.pull_time.present? ||
        info.ext_created_at.present? ||
        info.ext_updated_at.present?
    end
    with_pull_provenance.one? ? with_pull_provenance.first : nil
  end

  def unresolved_integrity_count(counts)
    counts.values_at(
      :purchases,
      :sale_items,
      :purchase_item_links,
      :purchase_item_purchase_identity,
      :duplicate_shopify_identity,
      :base_activation
    ).sum
  end

  def log_counts(label, counts)
    log "COUNTS label=#{label} #{counts.map { |key, value| "#{key}=#{value}" }.join(" ")}"
  end

  def log_checkpoint(phase, last_id, counts)
    attributes = counts.except(:reasons).map { |key, value| "#{key}=#{value}" }
    attributes << "reasons=#{counts.fetch(:reasons).sort.to_h.inspect}" if counts.key?(:reasons)
    attributes.unshift("last_id=#{last_id}") if last_id
    log "CHECKPOINT phase=#{phase} #{attributes.join(" ")}"
  end

  def log_unresolved(phase, candidate)
    log(
      "UNRESOLVED phase=#{phase} id=#{candidate.id} " \
        "details=#{candidate.details.inspect}"
    )
  end

  def log(message)
    output.puts(message)
  end
end

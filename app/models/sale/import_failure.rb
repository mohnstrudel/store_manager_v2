# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_import_failures
#
#  id              :bigint           not null, primary key
#  failure_count   :integer          default(0), not null
#  first_failed_at :datetime         not null
#  last_failed_at  :datetime         not null
#  message         :text             not null
#  resolved_at     :datetime
#  store_name      :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sale_id         :bigint
#  sentry_event_id :string
#  store_order_id  :string           not null
#
class Sale::ImportFailure < ApplicationRecord
  belongs_to :sale, optional: true

  enum :store_name, {woo: "woo", shopify: "shopify"}

  scope :unresolved, -> { where(resolved_at: nil) }

  def self.record_safely(**attributes)
    record(**attributes)
  rescue => error
    Sentry.capture_exception(error, extra: attributes.slice(:store_name, :store_order_id))
    nil
  end

  def self.record(store_name:, store_order_id:, message:, sentry_event_id:, failed_at:)
    transaction do
      failure = create_or_find_by!(store_name:, store_order_id:) do |new_failure|
        new_failure.assign_attributes(message:, first_failed_at: failed_at, last_failed_at: failed_at)
      end

      failure.with_lock { failure.register(message:, sentry_event_id:, failed_at:) }
    end
  end

  def self.resolve(store_name:, store_order_id:)
    find_by(store_name:, store_order_id:, resolved_at: nil)&.update!(resolved_at: Time.current)
  end

  def self.pull_unresolved_later(sale_ids:)
    unresolved.where(sale_id: sale_ids).to_a.each(&:pull_later).size
  end

  def register(message:, sentry_event_id:, failed_at:)
    return if resolved_at&.after?(failed_at)

    update!(
      sale: find_sale,
      message:,
      sentry_event_id:,
      failure_count: failure_count + 1,
      last_failed_at: failed_at,
      resolved_at: nil
    )
  end

  def store_order_number
    (shopify? && Sale::Shopify::OrderId.normalize(store_order_id)) || store_order_id
  end

  def pull_later
    shopify? ? Shopify::PullSaleJob.perform_later(store_order_id) : Woo::PullSalesJob.perform_later(id: store_order_id)
  end

  private

  def find_sale
    woo? ? Sale.find_by_woo_id(store_order_id) : Sale::Shopify::OrderId.find_sale(store_order_id)
  end
end

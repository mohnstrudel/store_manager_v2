# frozen_string_literal: true

# == Schema Information
#
# Table name: outbound_emails
#
#  id               :bigint           not null, primary key
#  accepted_at      :datetime
#  attempts         :integer          default(0), not null
#  body             :text
#  last_attempt_at  :datetime
#  last_error       :string
#  mail_kind        :string
#  product_title    :text
#  recipient        :string
#  recipient_name   :string
#  sender           :string
#  source           :string           not null
#  state            :string           default("pending"), not null
#  subject          :string
#  created_at       :datetime         not null
#  customer_id      :bigint
#  purchase_item_id :bigint           not null
#  sale_item_id     :bigint           not null
#  warehouse_id     :bigint           not null
#
class OutboundEmail < ApplicationRecord
  include Searchable

  set_search_scope :search, against: %i[recipient recipient_name subject product_title body]

  enum :source, {
    link: "link",
    warehouse_move: "warehouse_move",
    explicit_resend: "explicit_resend",
    baseline: "baseline"
  }

  enum :mail_kind, {
    order_status_updated: "order_status_updated",
    order_status_changed: "order_status_changed"
  }, validate: {allow_nil: true}

  enum :state, {
    pending: "pending",
    accepted: "accepted",
    simulated: "simulated",
    assumed_baseline: "assumed_baseline"
  }, default: :pending

  after_create_commit :enqueue_delivery, if: :pending?

  def deliver!
    failure = nil
    with_lock { failure = attempt_delivery if pending? }
    raise failure if failure
  end

  private

  def attempt_delivery
    if OutboundEmailMailer.perform_deliveries
      OutboundEmailMailer.stored(self).deliver_now
      record_attempt!(state: :accepted, accepted_at: Time.current)
    else
      record_attempt!(state: :simulated)
    end
    nil
  rescue => error
    record_attempt!(last_error: "#{error.class}: #{error.message}".truncate(500))
    error
  end

  def record_attempt!(last_error: nil, **attributes)
    update!(attempts: attempts + 1, last_attempt_at: Time.current, last_error:, **attributes)
  end

  def enqueue_delivery
    OutboundEmailDeliveryJob.perform_later(id)
  rescue => error
    Rails.logger.error("OutboundEmail #{id} enqueue failed: #{error.class}: #{error.message}")
  end
end

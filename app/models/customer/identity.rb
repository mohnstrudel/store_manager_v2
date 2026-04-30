# frozen_string_literal: true

module Customer::Identity
  extend ActiveSupport::Concern

  included do
    validate :identity_present
  end

  def name_and_email
    parts = [full_name.strip, email].compact_blank
    parts.join(" — ")
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def title
    full_name
  end

  private

  def identity_present
    return if [email, first_name, last_name, phone].any?(&:present?)
    return if store_infos.any? { |store_info| store_info.store_id.present? }

    errors.add(:base, "Customer must have contact details or store information")
  end
end

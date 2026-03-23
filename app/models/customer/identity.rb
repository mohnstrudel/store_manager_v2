# frozen_string_literal: true

module Customer::Identity
  extend ActiveSupport::Concern

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
end

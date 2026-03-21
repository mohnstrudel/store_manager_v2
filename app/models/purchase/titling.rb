# frozen_string_literal: true

module Purchase::Titling
  extend ActiveSupport::Concern

  def title
    "Purchase №#{id}: #{product.title}"
  end

  def full_title
    date = purchase_date || created_at
    "#{supplier.title} | #{product.full_title} | #{date&.strftime("%Y-%m-%d")}"
  end

  def which_edition
    edition ? edition.title : "-"
  end
end

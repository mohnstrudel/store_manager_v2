# frozen_string_literal: true

module Product::Titling
  extend ActiveSupport::Concern

  def update_full_title
    self.full_title = generate_full_title
    save!
  end

  def generate_full_title
    [base_title_part, brand_title_part].compact_blank.join(" | ")
  end

  def find_slug_candidate
    full_title
  end

  private

  def base_title_part
    return title if title == franchise.title

    "#{franchise.title} — #{title}"
  end

  def brand_title_part
    titles = if brands.loaded?
      brands.map(&:title)
    else
      brands.pluck(:title)
    end

    titles.compact_blank.join(", ").presence
  end
end

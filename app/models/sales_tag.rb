# frozen_string_literal: true

# == Schema Information
#
# Table name: sales_tags
#
#  id              :bigint           not null, primary key
#  color           :string           default("green"), not null
#  name            :string           not null
#  normalized_name :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class SalesTag < ApplicationRecord
  COLORS = %w[green pink sky violet olive].freeze
  DEFAULT_COLOR = COLORS.first
  MAX_NAME_LENGTH = 30

  has_many :sale_taggings, dependent: nil, inverse_of: :sales_tag
  has_many :sales, through: :sale_taggings

  attribute :color, default: DEFAULT_COLOR

  normalizes :name, with: ->(name) { name.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, " ").strip }

  before_validation :derive_normalized_name

  validates :name, presence: true
  validates :name, length: {maximum: MAX_NAME_LENGTH}, allow_blank: true
  validates :color, inclusion: {in: COLORS}
  validates_db_uniqueness_of :normalized_name

  scope :alphabetical, -> { order(:normalized_name, :id) }
  scope :with_usage_count, -> {
    left_joins(:sale_taggings).group(:id).select("sales_tags.*", "COUNT(sale_taggings.id) AS usage_count")
  }

  def self.find_or_create_normalized!(name:, color: DEFAULT_COLOR)
    candidate = new(name:, color:)
    candidate.validate!
    find_by(normalized_name: candidate.normalized_name) || candidate.tap(&:save!)
  rescue ActiveRecord::RecordInvalid
    duplicate = candidate.errors.delete(:normalized_name).present?
    raise ActiveRecord::RecordInvalid, candidate if candidate.errors.any? || !duplicate

    find_by(normalized_name: candidate.normalized_name) || raise_winner_missing(candidate)
  end

  def self.raise_winner_missing(candidate)
    candidate.errors.clear
    candidate.errors.add(:name, "changed while saving. Try again.")
    raise ActiveRecord::RecordInvalid, candidate
  end
  private_class_method :raise_winner_missing

  def revise!(attributes)
    update!(attributes)
  rescue ActiveRecord::RecordInvalid
    errors.add(:name, :taken) if errors.delete(:normalized_name).present?
    raise
  end

  def sort_key
    [normalized_name, id]
  end

  private

  def derive_normalized_name
    self.normalized_name = name&.downcase
  end
end

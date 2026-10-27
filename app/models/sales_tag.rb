# frozen_string_literal: true

# == Schema Information
#
# Table name: sales_tags
#
#  id              :bigint           not null, primary key
#  color           :string           default("gray"), not null
#  name            :string           not null
#  normalized_name :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class SalesTag < ApplicationRecord
  COLORS = %w[gray red yellow green blue violet fuchsia].freeze
  MAX_NAME_LENGTH = 30

  normalizes :name, with: ->(name) { name.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, " ").strip }

  before_validation :derive_normalized_name

  validates :name, presence: true
  validates :name, length: {maximum: MAX_NAME_LENGTH}, allow_blank: true
  validates :name, format: {with: /\A\S+( \S+)?\z/, message: "must be one or two words"}, allow_blank: true
  validates :color, inclusion: {in: COLORS}
  validates_db_uniqueness_of :normalized_name

  scope :alphabetical, -> { order(:normalized_name, :id) }
  scope :matching, lambda { |query|
    key = normalize_value_for(:name, query.to_s).downcase
    key.empty? ? all : where("normalized_name LIKE ?", "%#{sanitize_sql_like(key)}%")
  }

  def self.find_or_create_normalized!(name:, color: "gray")
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

  private

  def derive_normalized_name
    self.normalized_name = name&.downcase
  end
end

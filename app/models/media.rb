# frozen_string_literal: true
# == Schema Information
#
# Table name: media
#
#  id             :bigint           not null, primary key
#  alt            :string           default(""), not null
#  mediaable_type :string           not null
#  position       :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  mediaable_id   :bigint           not null
#
class Media < ApplicationRecord
  #
  # == Callbacks
  #
  after_update :destroy_if_image_removed

  #
  # == Associations
  #
  belongs_to :mediaable, polymorphic: true, inverse_of: :media

  has_one_attached :image, dependent: :purge_later do |attachable|
    attachable.variant :preview,
      format: :webp,
      resize_to_limit: [800, 800],
      preprocessed: true
    attachable.variant :thumb,
      format: :webp,
      resize_to_limit: [300, 300],
      preprocessed: true
    attachable.variant :nano,
      format: :webp,
      resize_to_limit: [120, 120],
      preprocessed: true
  end

  has_many :store_infos, as: :storable, dependent: :destroy

  #
  # == Delegates
  #
  delegate_missing_to :image

  #
  # == Scopes
  #
  scope :ordered, -> { order(position: :asc) }

  private

  def destroy_if_image_removed
    destroy if !image.attached? && persisted?
  end
end

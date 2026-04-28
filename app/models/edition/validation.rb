# frozen_string_literal: true

module Edition::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :_destroy

    validates :sku, presence: true, unless: :should_be_removed?
  end

  def should_be_removed?
    ActiveModel::Type::Boolean.new.cast(@_destroy)
  end
end

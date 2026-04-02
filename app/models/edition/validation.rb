# frozen_string_literal: true

module Edition::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :_destroy

    validates_db_uniqueness_of :sku, allow_blank: true, unless: :marked_for_editing_destruction?
  end

  def marked_for_editing_destruction?
    ActiveModel::Type::Boolean.new.cast(@_destroy)
  end
end

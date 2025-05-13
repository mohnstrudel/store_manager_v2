class Shopify::PullVariationsJob < ApplicationJob
  queue_as :default

  include Sanitizable

  def perform(product, parsed_variations)
    parsed_variations.each do |variant|
      Shopify::VariationCreator.new(product, variant).update_or_create!
    end
  end
end

class Shopify::PullEditionsJob < ApplicationJob
  queue_as :default

  include Sanitizable

  def perform(product, parsed_editions)
    parsed_editions.each do |variant|
      Shopify::EditionCreator.new(product, variant).update_or_create!
    end
  end
end

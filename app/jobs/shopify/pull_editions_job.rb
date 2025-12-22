# frozen_string_literal: true
class Shopify::PullEditionsJob < ApplicationJob
  queue_as :default

  include Sanitizable

  def perform(product, parsed_editions)
    parsed_editions.each do |pe|
      Shopify::EditionCreator.new(product, pe).update_or_create!
    end
  end
end

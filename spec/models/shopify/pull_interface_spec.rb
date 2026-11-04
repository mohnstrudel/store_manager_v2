# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shopify pull canonical interface" do
  canonical = Class.new do
    def fetch(*) = raise NotImplementedError

    def batch_size = raise NotImplementedError

    def importer_class = raise NotImplementedError

    def parser_class = raise NotImplementedError
  end

  [Product::Shopify::Pull, Sale::Shopify::Pull].each do |pull_class|
    describe pull_class do # rubocop:disable RSpec/EmptyExampleGroup -- implement_canonical_interface generates the `it` example
      implement_canonical_interface(canonical)
    end
  end
end

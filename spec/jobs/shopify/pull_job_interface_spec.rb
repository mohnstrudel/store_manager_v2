# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Shopify pull job canonical interface" do
  canonical = Class.new do
    def parser_class = raise NotImplementedError

    def creator_class = raise NotImplementedError

    def batch_size = raise NotImplementedError

    def fetch_from_api(*) = raise NotImplementedError
  end

  [Shopify::PullProductsJob, Shopify::PullSalesJob].each do |job_class|
    describe job_class do # rubocop:disable RSpec/EmptyExampleGroup -- implement_canonical_interface generates the `it` example
      implement_canonical_interface(canonical)
    end
  end

  it "keeps PullProductsJob and PullSalesJob interchangeable under BasePullJob" do
    expect(Shopify::PullProductsJob).to have_matching_interfaces(
      Shopify::PullSalesJob,
      methods: %i[parser_class creator_class batch_size fetch_from_api]
    )
  end
end

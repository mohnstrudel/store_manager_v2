# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullSalesJob do
  let(:job) { described_class.new }
  let(:client) { instance_double(Woo::Api::Client) }
  let(:woo_orders) { [{id: 1}, {id: 2}] }
  let(:parsed_orders) { [{sale: {woo_id: 1}}, {sale: {woo_id: 2}}] }

  before do
    allow(Woo::Api::Client).to receive(:new).and_return(client)
    allow(Sale::Woo::Parser).to receive(:parse_all).and_return(parsed_orders)
    allow(Sale::Woo::Importer).to receive(:import_all)
  end

  describe "#perform" do
    it "imports a single order when an id is given", :aggregate_failures do
      allow(client).to receive(:fetch_order).with("123").and_return(woo_orders.first)

      expect(job.perform(id: "123")).to be_nil

      expect(Sale::Woo::Parser).to have_received(:parse_all).with([woo_orders.first])
      expect(Sale::Woo::Importer).to have_received(:import_all).with(parsed_orders)
    end

    it "imports the default number of orders without an id", :aggregate_failures do
      allow(client).to receive(:fetch_orders).with(2700, nil).and_return(woo_orders)

      job.perform

      expect(Sale::Woo::Parser).to have_received(:parse_all).with(woo_orders)
      expect(Sale::Woo::Importer).to have_received(:import_all).with(parsed_orders)
    end

    it "passes a custom limit and page count to the client" do
      allow(client).to receive(:fetch_orders).with(100, 5).and_return(woo_orders)

      job.perform(limit: 100, pages: 5)

      expect(client).to have_received(:fetch_orders).with(100, 5)
    end
  end
end

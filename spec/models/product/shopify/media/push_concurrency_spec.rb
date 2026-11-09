# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push, ".call" do
  include Helpers::ShopifyMediaScenarios

  context "when two pushes overlap on one product" do
    self.use_transactional_tests = false

    let(:product_store_id) { "gid://shopify/Product/123" }

    after do
      ActiveRecord::Base.connection.truncate_tables(
        *(ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata])
      )
    end

    it "attaches each new image once when the second push waits for the first to finish" do
      product = create(:product, :synced)
      media = create(:media, mediaable: product, alt: "Image")
      listed_nodes = []
      attach_started = Queue.new
      release_attach = Queue.new
      api_client = instance_spy(Shopify::Api::Client)
      allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
      allow(ActiveStorage::Blob.service).to receive(:exist?).and_return(true)
      allow(api_client).to receive_messages(update_media: [], reorder_media: nil)
      allow(api_client).to receive(:fetch_product) do
        {"id" => product_store_id, "media" => {"nodes" => listed_nodes.dup}}
      end
      allow(api_client).to receive(:attach_media) do
        attach_started << true
        release_attach.pop(timeout: 5)
        listed_nodes << {"id" => media_gid(1), "status" => "READY"}
        [{"id" => media_gid(1), "status" => "PROCESSING"}]
      end

      first = Thread.new { push_in_own_connection(product.id) }
      attach_started.pop(timeout: 5)
      second = Thread.new { push_in_own_connection(product.id) }
      wait_until_a_session_waits_on_a_lock
      release_attach << true

      expect([first, second].map(&:value)).to eq([:waiting_for_shopify, :completed])
      expect(api_client).to have_received(:attach_media).once
      expect(media.reload.shopify_store_id).to eq(media_gid(1))
    ensure
      release_attach&.push(true)
      [first, second].compact.each { |thread| thread.join(5) }
    end

    def push_in_own_connection(product_id)
      ActiveStorage::Current.url_options = {host: "example.com"}
      ActiveRecord::Base.connection_pool.with_connection do
        described_class.call(product_id:, product_store_id:)
      end
      :completed
    rescue described_class::NotReady
      :waiting_for_shopify
    end

    def wait_until_a_session_waits_on_a_lock
      Timeout.timeout(5) do
        sleep 0.01 until ActiveRecord::Base.connection.select_value(<<~SQL.squish).positive?
          SELECT count(*) FROM pg_stat_activity
          WHERE datname = current_database() AND wait_event_type = 'Lock'
        SQL
      end
    end
  end
end

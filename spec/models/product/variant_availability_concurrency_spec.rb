# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::VariantAvailability do
  describe "concurrent real Variant transitions" do
    it "serializes competing activation, deactivation, and removal under the Product lock" do
      fixture = in_committed_connection do
        franchise = Franchise.create!(title: "Concurrency #{SecureRandom.hex(6)}")
        product = Product.create!(
          franchise:,
          shape: Product.default_shape,
          title: "Concurrent Variants #{SecureRandom.hex(6)}"
        )
        versions = [
          Version.create!(value: "Concurrent A #{SecureRandom.hex(4)}"),
          Version.create!(value: "Concurrent B #{SecureRandom.hex(4)}")
        ]

        {
          franchise_id: franchise.id,
          product_id: product.id,
          version_ids: versions.map(&:id)
        }
      end

      variant_ids = run_concurrently(
        -> {
          Variant.create!(
            product_id: fixture[:product_id],
            version_id: fixture[:version_ids].first,
            sku: "concurrent-a-#{SecureRandom.hex(4)}"
          ).id
        },
        -> {
          Variant.create!(
            product_id: fixture[:product_id],
            version_id: fixture[:version_ids].second,
            sku: "concurrent-b-#{SecureRandom.hex(4)}"
          ).id
        }
      )

      activated_product = Product.find(fixture[:product_id])
      expect(activated_product.variants.base_models.count).to eq(1)
      expect(activated_product.variants.active.real.ids).to match_array(variant_ids)
      expect(activated_product.base_variant).to be_deactivated

      run_concurrently(
        -> { Variant.find(variant_ids.first).update!(deactivated_at: Time.current) },
        -> { Variant.find(variant_ids.second).destroy! }
      )

      final_product = Product.find(fixture[:product_id])
      expect(final_product.variants.base_models.count).to eq(1)
      expect(final_product.variants.active.real).to be_empty
      expect(final_product.variants.active).to contain_exactly(final_product.base_variant)
      expect(final_product.base_variant).not_to be_deactivated
    ensure
      cleanup_committed_fixture(fixture) if fixture
    end

    def in_committed_connection(&)
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection(&)
      end.value
    end

    def run_concurrently(*operations)
      ready = Queue.new
      start = Queue.new
      threads = operations.map do |operation|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            start.pop
            operation.call
          end
        end
      end

      operations.size.times { ready.pop }
      operations.size.times { start << true }
      threads.map(&:value)
    end

    def cleanup_committed_fixture(fixture)
      in_committed_connection do
        Product.find_by(id: fixture[:product_id])&.destroy!
        Version.where(id: fixture[:version_ids]).destroy_all
        Franchise.find_by(id: fixture[:franchise_id])&.destroy!
        Audited::Audit
          .where(associated_type: "Franchise", associated_id: fixture[:franchise_id])
          .delete_all
      end
    end
  end
end

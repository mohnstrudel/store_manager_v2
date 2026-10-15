# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem::Linking, ".link_exact!" do
  context "with concurrent same-pair links" do
    self.use_transactional_tests = false

    after do
      ActiveRecord::Base.connection.truncate_tables(
        *(ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata])
      )
    end

    it "records one intent when two sessions link the same purchase item to the same sale item" do
      product = create(:product)
      purchase_item = create(:purchase_item, purchase: create(:purchase, product:))
      sale_item = create(:sale_item, sale: create(:sale, status: Sale.active_status_names.first), product:, variant: product.base_variant)
      linked = Queue.new
      release_link = Queue.new
      second_pid = Queue.new

      first = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          PurchaseItem.transaction do
            PurchaseItem.link_exact!(assignments: [{purchase_item: PurchaseItem.find(purchase_item.id), sale_item:}])
            linked << true
            release_link.pop(timeout: 5)
          end
        end
      end
      linked.pop(timeout: 5)

      second = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          second_pid << connection.raw_connection.backend_pid
          PurchaseItem.link_exact!(assignments: [{purchase_item: PurchaseItem.find(purchase_item.id), sale_item:}])
        end
      end
      wait_for_lock(second_pid.pop(timeout: 5))
      release_link << true
      [first, second].each(&:value)

      expect(OutboundEmail.where(purchase_item_id: purchase_item.id).count).to eq(1)
    ensure
      release_link&.push(true)
      [first, second].compact.each { |thread| thread.join(5) }
    end

    it "keeps a warehouse move as the latest pair when a relink waits for it" do
      product = create(:product)
      origin = create(:warehouse)
      destination = create(:warehouse)
      sale_item = create(:sale_item, sale: create(:sale), product:, variant: product.base_variant)
      purchase_item = create(:purchase_item,
        purchase: create(:purchase, product:, variant: product.base_variant),
        sale_item:, warehouse: origin)
      create(:outbound_email, :assumed_baseline,
        purchase_item_id: purchase_item.id, sale_item_id: sale_item.id, warehouse_id: origin.id)
      notification = create(:notification, event_type: :warehouse_changed, status: :active)
      create(:warehouse_transition, notification:, from_warehouse: origin, to_warehouse: destination)
      moved = Queue.new
      release_move = Queue.new
      relink_pid = Queue.new

      mover = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          PurchaseItem.transaction do
            PurchaseItem.move_to_warehouse!(purchase_item_ids: [purchase_item.id], warehouse_id: destination.id)
            moved << true
            release_move.pop(timeout: 5)
          end
        end
      end
      moved.pop(timeout: 5)

      relinker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          relink_pid << connection.raw_connection.backend_pid
          PurchaseItem.link_exact!(assignments: [], unlink_purchase_items: [PurchaseItem.find(purchase_item.id)])
          PurchaseItem.link_exact!(assignments: [{purchase_item: PurchaseItem.find(purchase_item.id), sale_item:}])
        end
      end
      wait_for_lock(relink_pid.pop(timeout: 5))
      release_move << true
      [mover, relinker].each(&:value)

      expect(purchase_item.reload).to have_attributes(sale_item_id: sale_item.id, warehouse_id: destination.id)
      expect(OutboundEmail.where(purchase_item_id: purchase_item.id).order(:id).pluck(:source, :warehouse_id))
        .to eq([["baseline", origin.id], ["warehouse_move", destination.id]])
    ensure
      release_move&.push(true)
      [mover, relinker].compact.each { |thread| thread.join(5) }
    end

    def wait_for_lock(pid)
      Timeout.timeout(5) do
        sleep 0.01 until ActiveRecord::Base.connection.select_value(<<~SQL.squish).positive?
          SELECT count(*) FROM pg_stat_activity
          WHERE pid = #{pid.to_i} AND wait_event_type = 'Lock'
        SQL
      end
    end
  end
end

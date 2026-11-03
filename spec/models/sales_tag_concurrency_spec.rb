# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalesTag do
  self.use_transactional_tests = false

  after do
    ActiveRecord::Base.connection.truncate_tables(
      *(ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata])
    )
  end

  describe ".find_or_create_normalized!" do
    context "with concurrent creators of the same identity" do
      it "returns the committed winner to the waiting creator without changing its name or color" do
        inserted = Queue.new
        release_winner = Queue.new
        loser_pid = Queue.new

        winner = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            described_class.transaction do
              tag = described_class.find_or_create_normalized!(name: "VIP Order", color: "sky")
              inserted << true
              release_winner.pop(timeout: 5)
              tag
            end
          end
        end
        inserted.pop(timeout: 5)

        loser = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            loser_pid << connection.raw_connection.backend_pid
            described_class.find_or_create_normalized!(name: "vip order", color: "pink")
          end
        end
        wait_for_lock(loser_pid.pop(timeout: 5))
        release_winner << true
        winning_tag, reused_tag = [winner, loser].map(&:value)

        expect(reused_tag.id).to eq(winning_tag.id)
        expect(described_class.where(normalized_name: "vip order").count).to eq(1)
        expect(described_class.find(winning_tag.id)).to have_attributes(name: "VIP Order", color: "sky")
      ensure
        release_winner&.push(true)
        [winner, loser].compact.each { |thread| thread.join(5) }
      end

      it "lets creators on different sales share one identity and each keep their assignment" do
        first_sale, second_sale = create_list(:sale, 2)
        inserted = Queue.new
        release_winner = Queue.new
        loser_pid = Queue.new

        winner = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ActiveRecord::Base.transaction do
              first_sale.replace_tags!(ids: [], original_ids: [], new_tags: [{name: "VIP Order", color: "sky"}])
              inserted << true
              release_winner.pop(timeout: 5)
            end
          end
        end
        inserted.pop(timeout: 5)

        loser = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            loser_pid << connection.raw_connection.backend_pid
            second_sale.replace_tags!(ids: [], original_ids: [], new_tags: [{name: "vip order", color: "pink"}])
          end
        end
        wait_for_lock(loser_pid.pop(timeout: 5))
        release_winner << true
        [winner, loser].each(&:value)

        expect(described_class.where(normalized_name: "vip order").pluck(:name, :color)).to eq([["VIP Order", "sky"]])
        expect(SaleTagging.pluck(:sale_id)).to contain_exactly(first_sale.id, second_sale.id)
        expect(SaleTagging.distinct.pluck(:sales_tag_id).size).to eq(1)
      ensure
        release_winner&.push(true)
        [winner, loser].compact.each { |thread| thread.join(5) }
      end
    end
  end

  describe "#destroy! against concurrent assignment" do
    it "cascades an assignment that committed before the deletion, keeping the sale and its other tags" do
      sale = create(:sale)
      vip, rush = %w[VIP Rush].map { |name| create(:sales_tag, name:) }
      assigned = Queue.new
      release_assignment = Queue.new
      deleter_pid = Queue.new

      assigner = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActiveRecord::Base.transaction do
            Sale.find(sale.id).replace_tags!(ids: [vip.id, rush.id], original_ids: [])
            assigned << true
            release_assignment.pop(timeout: 5)
          end
        end
      end
      assigned.pop(timeout: 5)

      deleter = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          deleter_pid << connection.raw_connection.backend_pid
          described_class.find(vip.id).destroy!
        end
      end
      wait_for_lock(deleter_pid.pop(timeout: 5))
      release_assignment << true
      [assigner, deleter].each(&:value)

      expect(described_class.exists?(vip.id)).to be(false)
      expect(SaleTagging.where(sales_tag_id: vip.id)).to be_empty
      expect(SaleTagging.where(sale_id: sale.id).pluck(:sales_tag_id)).to eq([rush.id])
      expect(Sale.exists?(sale.id)).to be(true)
    ensure
      release_assignment&.push(true)
      [assigner, deleter].compact.each { |thread| thread.join(5) }
    end

    it "fails an assignment that waited on a deletion without creating its proposed tag or changing the sale" do
      sale = create(:sale)
      zebra, vip = %w[Zebra VIP].map { |name| create(:sales_tag, name:) }
      SaleTagging.create!(sale:, sales_tag: zebra)
      deleted = Queue.new
      release_deletion = Queue.new
      assigner_pid = Queue.new

      deleter = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.transaction do
            described_class.find(vip.id).destroy!
            deleted << true
            release_deletion.pop(timeout: 5)
          end
        end
      end
      deleted.pop(timeout: 5)

      assigner = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          assigner_pid << connection.raw_connection.backend_pid
          target = Sale.find(sale.id)
          begin
            target.replace_tags!(ids: [zebra.id, vip.id], original_ids: [zebra.id], new_tags: [{name: "Rush", color: "pink"}])
          rescue ActiveRecord::RecordInvalid
            target.errors[:tags]
          end
        end
      end
      wait_for_lock(assigner_pid.pop(timeout: 5))
      release_deletion << true
      deleter.value

      expect(assigner.value).to eq([Sale::Tagging::MISSING_SELECTION_MESSAGE])
      expect(described_class.exists?(vip.id)).to be(false)
      expect(described_class.exists?(normalized_name: "rush")).to be(false)
      expect(SaleTagging.where(sale_id: sale.id).pluck(:sales_tag_id)).to eq([zebra.id])
    ensure
      release_deletion&.push(true)
      [deleter, assigner].compact.each { |thread| thread.join(5) }
    end
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

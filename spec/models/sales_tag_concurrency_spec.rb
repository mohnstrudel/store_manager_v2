# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalesTag, ".find_or_create_normalized!" do
  context "with concurrent creators of the same identity" do
    self.use_transactional_tests = false

    after do
      ActiveRecord::Base.connection.truncate_tables(
        *(ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata])
      )
    end

    it "returns the committed winner to the waiting creator without changing its name or color" do
      inserted = Queue.new
      release_winner = Queue.new
      loser_pid = Queue.new

      winner = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.transaction do
            tag = described_class.find_or_create_normalized!(name: "VIP Order", color: "blue")
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
          described_class.find_or_create_normalized!(name: "vip order", color: "red")
        end
      end
      wait_for_lock(loser_pid.pop(timeout: 5))
      release_winner << true
      winning_tag, reused_tag = [winner, loser].map(&:value)

      expect(reused_tag.id).to eq(winning_tag.id)
      expect(described_class.where(normalized_name: "vip order").count).to eq(1)
      expect(described_class.find(winning_tag.id)).to have_attributes(name: "VIP Order", color: "blue")
    ensure
      release_winner&.push(true)
      [winner, loser].compact.each { |thread| thread.join(5) }
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

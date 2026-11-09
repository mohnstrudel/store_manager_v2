# frozen_string_literal: true

class BrokenSales::Counts
  def initialize(integrity: Variant::AssignmentIntegrity.new)
    @integrity = integrity
  end

  def total
    by_tab.values.sum
  end

  def by_tab
    @by_tab ||= integrity.counts.merge(import_failures: Sale::ImportFailure.unresolved.count)
  end

  private

  attr_reader :integrity
end

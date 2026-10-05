# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: expense_rates
#
#  id           :bigint           not null, primary key
#  name         :string           not null
#  rate_percent :decimal(5, 2)    not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
RSpec.describe ExpenseRate do
  describe "validations" do
    it "requires a name" do
      expect(build(:expense_rate, name: nil)).not_to be_valid
    end

    it "rejects duplicate names" do
      create(:expense_rate, name: "Payroll")

      expect(build(:expense_rate, name: "Payroll")).not_to be_valid
    end

    it "requires rate_percent between 0 and 100" do
      expect(build(:expense_rate, rate_percent: nil)).not_to be_valid
      expect(build(:expense_rate, rate_percent: -1)).not_to be_valid
      expect(build(:expense_rate, rate_percent: 101)).not_to be_valid
      expect(build(:expense_rate, rate_percent: 0)).to be_valid
      expect(build(:expense_rate, rate_percent: 100)).to be_valid
    end
  end

  describe ".ordered" do
    it "orders by rate descending, then name" do
      second = create(:expense_rate, name: "Payroll", rate_percent: 15)
      first = create(:expense_rate, name: "Rent", rate_percent: 20)
      third = create(:expense_rate, name: "Advertising", rate_percent: 5)
      fourth = create(:expense_rate, name: "Warehouse", rate_percent: 5)

      expect(described_class.ordered).to eq([first, second, third, fourth])
    end
  end

  describe ".combined_fraction" do
    it "sums rates and converts them to a fraction" do
      create(:expense_rate, rate_percent: 15)
      create(:expense_rate, rate_percent: 2.5)

      expect(described_class.combined_fraction).to eq(BigDecimal("0.175"))
    end

    it "returns zero without rates" do
      expect(described_class.combined_fraction).to eq(0)
    end
  end
end

# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  external_name             :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require "rails_helper"

RSpec.describe Warehouse, type: :model do
  describe "validations" do
    it "validates presence of name" do
      warehouse = described_class.new(name: nil, external_name: "External Name")
      expect(warehouse).not_to be_valid
    end

    it "validates presence of external name" do
      warehouse = described_class.new(name: "Name", external_name: nil)
      expect(warehouse).not_to be_valid
    end
  end

  describe "before_save" do
    it "ensures only one instance is default" do
      create(:warehouse, is_default: true)
      create(:warehouse, is_default: true)
      default_warehouses_size = described_class.where(is_default: true).size

      expect(default_warehouses_size).to eq 1
    end
  end
end

# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  desc_de                   :string
#  desc_en                   :string
#  external_name             :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  position                  :integer          default(1), not null
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

  describe "attributes" do
    it "has English and German descriptions" do
      warehouse = build(:warehouse)
      expect(warehouse.desc_en).to eq("English Description")
      expect(warehouse.desc_de).to eq("German Description")
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end
end

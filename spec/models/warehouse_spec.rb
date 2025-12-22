# frozen_string_literal: true
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
#  external_name_de          :string
#  external_name_en          :string
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
      warehouse = described_class.new(name: nil)
      expect(warehouse).not_to be_valid
    end

    it "allows empty external names" do
      warehouse = described_class.new(name: "Name", external_name_de: nil, external_name_en: nil)
      expect(warehouse).to be_valid
    end
  end

  describe "attributes" do
    it "has English and German descriptions" do # rubocop:todo RSpec/MultipleExpectations
      warehouse = build(:warehouse)
      expect(warehouse.desc_en).to eq("English Description")
      expect(warehouse.desc_de).to eq("German Description")
    end

    it "has English and German external names" do # rubocop:todo RSpec/MultipleExpectations
      warehouse = build(:warehouse)
      expect(warehouse.external_name_en).to match(/External Name \d+/)
      expect(warehouse.external_name_de).to match(/Externer Name \d+/)
    end

    describe "external name display" do
      it "has both German and English external names" do # rubocop:todo RSpec/MultipleExpectations
        warehouse = build(:warehouse, external_name_de: "Deutscher Name", external_name_en: "English Name")
        expect(warehouse.external_name_de).to eq("Deutscher Name")
        expect(warehouse.external_name_en).to eq("English Name")
      end

      it "can have only German external name" do # rubocop:todo RSpec/MultipleExpectations
        warehouse = build(:warehouse, external_name_de: "Deutscher Name", external_name_en: nil)
        expect(warehouse.external_name_de).to eq("Deutscher Name")
        expect(warehouse.external_name_en).to be_nil
      end

      it "can have only English external name" do # rubocop:todo RSpec/MultipleExpectations
        warehouse = build(:warehouse, external_name_de: nil, external_name_en: "English Name")
        expect(warehouse.external_name_de).to be_nil
        expect(warehouse.external_name_en).to eq("English Name")
      end
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end
end

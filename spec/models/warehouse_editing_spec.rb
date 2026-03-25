# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse do
  describe "#create_from_form!" do
    let!(:existing_default) { create(:warehouse, :default) }
    let(:warehouse) { described_class.new }

    # rubocop:disable RSpec/MultipleExpectations
    it "rejects creating a new default while another default exists" do
      expect {
        warehouse.create_from_form!(
          {name: "New Default", is_default: true},
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      aggregate_failures do
        expect(warehouse).not_to be_persisted
        expect(warehouse.errors[:is_default]).to include("conflict")
        expect(existing_default.reload.is_default).to be(true)
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "#apply_form_changes!" do
    let(:warehouse) { create(:warehouse) }

    it "syncs transitions only when transition ids are the only update" do
      destination = create(:warehouse)

      result = warehouse.apply_form_changes!(
        attributes: {"to_warehouse_ids" => [destination.id.to_s]},
        transition_ids: [destination.id.to_s],
        media_attributes: [],
        new_media_images: []
      )

      aggregate_failures do
        expect(result).to eq(Warehouse::Editing::TRANSITIONS_UPDATED)
        expect(warehouse.from_transitions.where(to_warehouse: destination)).to exist
      end
    end

    it "updates attributes and syncs transitions" do
      destination = create(:warehouse)

      result = warehouse.apply_form_changes!(
        attributes: {"name" => "Updated Name"},
        transition_ids: [destination.id.to_s],
        media_attributes: [],
        new_media_images: []
      )

      aggregate_failures do
        expect(result).to eq(Warehouse::Editing::WAREHOUSE_UPDATED)
        expect(warehouse.reload.name).to eq("Updated Name")
        expect(warehouse.from_transitions.where(to_warehouse: destination)).to exist
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "rejects switching to default while another default exists" do
      existing_default = create(:warehouse, :default)

      expect {
        warehouse.apply_form_changes!(
          attributes: {is_default: true},
          transition_ids: [],
          media_attributes: [],
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      aggregate_failures do
        expect(warehouse.reload.is_default).to be(false)
        expect(existing_default.reload.is_default).to be(true)
        expect(warehouse.errors[:is_default]).to include("conflict")
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "#update_position!" do
    let!(:warehouse_one) { create(:warehouse, position: 1) }
    let(:warehouse) { create(:warehouse, position: 2) }
    let!(:warehouse_three) { create(:warehouse, position: 3) }

    it "updates the warehouse position within the ordered list" do
      warehouse.update_position!(1)

      aggregate_failures do
        expect(warehouse.reload.position).to eq(1)
        expect(warehouse_one.reload.position).to eq(2)
        expect(warehouse_three.reload.position).to eq(3)
      end
    end
  end
end

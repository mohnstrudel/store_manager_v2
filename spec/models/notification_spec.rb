# frozen_string_literal: true
# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  event_type :integer          default("product_purchased"), not null
#  name       :string           not null
#  status     :integer          default("disabled"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe Notification do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to eq({"disabled" => 0, "active" => 1})
    end

    it "defines event_type enum" do
      expect(described_class.event_types).to eq({"product_purchased" => 0, "warehouse_changed" => 1})
    end
  end

  describe "associations" do
    it "has many warehouse transitions" do # rubocop:todo RSpec/MultipleExpectations
      association = described_class.reflect_on_association(:warehouse_transitions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:nullify)
    end
  end
end

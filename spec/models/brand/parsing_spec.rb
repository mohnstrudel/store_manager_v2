# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe Brand::Parsing do
  describe ".parse_brand" do
    it "extracts brand name after by" do
      expect(Brand.parse_brand("Asuka by Prime 1 Studio")).to eq("Prime 1 Studio")
    end

    it "extracts brand name after von/vom variants" do
      expect(Brand.parse_brand("Asuka von Kotobukiya")).to eq("Kotobukiya")
      expect(Brand.parse_brand("Asuka vom Alter")).to eq("Alter")
    end

    it "returns nil when no brand token is present" do
      expect(Brand.parse_brand("Asuka Figure")).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations

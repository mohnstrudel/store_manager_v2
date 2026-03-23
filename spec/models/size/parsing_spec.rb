# frozen_string_literal: true

require "rails_helper"

RSpec.describe Size::Parsing do
  describe ".numeric_size_match" do
    it "matches colon-separated numeric sizes" do
      expect("1:4".match?(Size.numeric_size_match)).to be true
    end

    it "matches slash-separated numeric sizes" do
      expect("1/4".match?(Size.numeric_size_match)).to be true
    end
  end

  describe ".parse_size" do
    it "returns the parsed size when the title contains one size" do
      expect(Size.parse_size("Something 1/4")).to eq("1:4")
    end

    it "returns an array when the title contains multiple sizes" do
      expect(Size.parse_size("1/4 and 1/6")).to eq(["1:4", "1:6"])
    end
  end

  describe ".sanitize_size" do
    it "normalizes slash sizes to colon sizes" do
      expect(Size.sanitize_size("Something 1/4")).to eq("Something 1:4")
    end
  end
end

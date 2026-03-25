# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormattingHelper do
  describe "#format_purchased_sold_ratio" do
    it "does not raise when sold is nil" do
      expect { helper.format_purchased_sold_ratio(1, nil) }.not_to raise_error
      expect(helper.format_purchased_sold_ratio(1, nil)).to include("1")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormattingHelper do
  describe "#format_money" do
    it "returns nil for a real zero amount" do
      expect(helper.format_money(0)).to be_nil
    end

    it "returns nil for a blank amount" do
      expect(helper.format_money(nil)).to be_nil
    end

    it "formats a non-zero amount" do
      expect(helper.format_money(1000)).to eq("1 000")
    end
  end

  describe "#safe_blank_render" do
    it "returns nil for a blank value" do
      expect(helper.safe_blank_render(nil)).to be_nil
      expect(helper.safe_blank_render("")).to be_nil
    end

    it "returns a real non-blank zero unchanged, unlike format_money" do
      expect(helper.safe_blank_render(0)).to eq(0)
    end
  end

  describe "#format_purchased_sold_ratio" do
    it "does not raise when sold is nil" do
      expect { helper.format_purchased_sold_ratio(1, nil) }.not_to raise_error
      expect(helper.format_purchased_sold_ratio(1, nil)).to include("1")
    end
  end

  describe "#payment_pie_total" do
    it "returns expected_revenue when it already covers received + outstanding" do
      expect(helper.payment_pie_total(1000, 900, 100)).to eq(1000.to_d)
    end

    it "falls back to received + outstanding when a Shopify order edit shrank expected_revenue below them" do
      expect(helper.payment_pie_total(900, 900, 100)).to eq(1000.to_d)
    end

    it "returns nil when expected_revenue is nil" do
      expect(helper.payment_pie_total(nil, 900, 100)).to be_nil
    end

    it "treats nil received/outstanding as zero" do
      expect(helper.payment_pie_total(500, nil, nil)).to eq(500.to_d)
    end
  end

  describe "#decimal_field_value" do
    it "keeps two decimal places instead of BigDecimal#to_s dropping trailing zeros" do
      expect(helper.decimal_field_value(BigDecimal("10.00"))).to eq("10.00")
      expect(helper.decimal_field_value(BigDecimal("3.30"))).to eq("3.30")
    end

    it "returns a blank string for nil, matching plain #to_s" do
      expect(helper.decimal_field_value(nil)).to eq("")
    end
  end

  describe "#percent_of" do
    it "rounds to the nearest whole percent" do
      expect(helper.percent_of(1, 3)).to eq(33)
    end

    it "returns nil when whole is nil or zero" do
      expect(helper.percent_of(1, nil)).to be_nil
      expect(helper.percent_of(1, 0)).to be_nil
    end

    it "returns nil when part is nil" do
      expect(helper.percent_of(nil, 100)).to be_nil
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: sales_tags
#
#  id              :bigint           not null, primary key
#  color           :string           default("gray"), not null
#  name            :string           not null
#  normalized_name :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
RSpec.describe SalesTag do
  describe ".find_or_create_normalized!" do
    it "trims, collapses Unicode whitespace, preserves case and derives the lowercase key" do
      tag = described_class.find_or_create_normalized!(name: "  VIP \u00A0\u3000 Order  ", color: "blue")

      expect(tag).to have_attributes(name: "VIP Order", normalized_name: "vip order", color: "blue")
    end

    it "folds compatibility characters with NFKC" do
      tag = described_class.find_or_create_normalized!(name: "ＶＩＰ")

      expect(tag).to have_attributes(name: "VIP", normalized_name: "vip", color: "gray")
    end

    it "reuses an existing identity and keeps its name and color" do
      original = described_class.find_or_create_normalized!(name: "VIP Order", color: "blue")

      reused = described_class.find_or_create_normalized!(name: "vip order", color: "red")

      expect(reused).to eq(original)
      expect(described_class.count).to eq(1)
      expect(reused.reload).to have_attributes(name: "VIP Order", color: "blue")
    end

    it "accepts thirty characters and counts codepoints rather than bytes" do
      expect(described_class.find_or_create_normalized!(name: "x" * 30).name).to eq("x" * 30)
      expect(described_class.find_or_create_normalized!(name: "é" * 30).name).to eq("é" * 30)
    end

    it "rejects invalid names and colors without creating a record" do
      {
        "x" * 31 => [:name, "is too long (maximum is 30 characters)"],
        "one two three" => [:name, "must be one or two words"],
        " \u00A0 " => [:name, "can't be blank"]
      }.each do |name, (attribute, message)|
        expect { described_class.find_or_create_normalized!(name:) }
          .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[attribute]).to eq([message]) }
      end

      expect { described_class.find_or_create_normalized!(name: "Rush", color: "pink") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:color]).to eq(["is not included in the list"]) }
      expect(described_class.count).to eq(0)
    end

    it "does not reuse an existing identity when another field is invalid and reports only name and color errors" do
      original = create(:sales_tag, name: "VIP Order", color: "blue")

      expect { described_class.find_or_create_normalized!(name: "vip order", color: "pink") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error|
          expect(error.record.errors.attribute_names).to eq([:color])
        }
      expect(described_class.count).to eq(1)
      expect(original.reload).to have_attributes(name: "VIP Order", color: "blue")
    end

    it "returns a validation error when the winning tag disappears after a collision" do
      create(:sales_tag, name: "Rush")
      allow(described_class).to receive(:find_by).and_return(nil)

      expect { described_class.find_or_create_normalized!(name: "rush") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:name]).to eq(["changed while saving. Try again."]) }
    end
  end

  describe ".matching" do
    it "treats the query as a case-insensitive literal substring of the normalized name" do
      vip = create(:sales_tag, name: "VIP Order")
      create(:sales_tag, name: "Rush")
      percent = create(:sales_tag, name: "50%_off")

      expect(described_class.matching(" vip ")).to contain_exactly(vip)
      expect(described_class.matching("%")).to contain_exactly(percent)
      expect(described_class.matching("_")).to contain_exactly(percent)
      expect(described_class.matching("").count).to eq(3)
    end
  end

  describe ".alphabetical" do
    it "orders by normalized name then id" do
      zebra = create(:sales_tag, name: "zebra")
      apple = create(:sales_tag, name: "Apple")
      banana = create(:sales_tag, name: "banana")

      expect(described_class.alphabetical).to eq([apple, banana, zebra])
    end
  end
end

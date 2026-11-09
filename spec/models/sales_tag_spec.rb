# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: sales_tags
#
#  id              :bigint           not null, primary key
#  color           :string           default("green"), not null
#  name            :string           not null
#  normalized_name :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
RSpec.describe SalesTag do
  describe "default color" do
    it "is green in the model, whatever default the column carries" do
      described_class.transaction(requires_new: true) do
        described_class.connection.change_column_default(:sales_tags, :color, "yellow")
        described_class.reset_column_information

        expect(described_class.new.color).to eq("green")
        raise ActiveRecord::Rollback
      end
    ensure
      described_class.reset_column_information
    end
  end

  describe ".find_or_create_normalized" do
    it "trims, collapses Unicode whitespace, preserves case and derives the lowercase key" do
      tag = described_class.find_or_create_normalized(name: "  VIP \u00A0\u3000 Order  ", color: "sky")

      expect(tag).to have_attributes(name: "VIP Order", normalized_name: "vip order", color: "sky")
    end

    it "folds compatibility characters with NFKC" do
      tag = described_class.find_or_create_normalized(name: "ＶＩＰ")

      expect(tag).to have_attributes(name: "VIP", normalized_name: "vip", color: "green")
    end

    it "no longer offers gray" do
      expect(described_class::COLORS).not_to include("gray")
      expect { described_class.find_or_create_normalized(name: "Rush", color: "gray") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:color]).to eq(["is not included in the list"]) }
    end

    it "reuses an existing identity and keeps its name and color" do
      original = described_class.find_or_create_normalized(name: "VIP Order", color: "sky")

      reused = described_class.find_or_create_normalized(name: "vip order", color: "pink")

      expect(reused).to eq(original)
      expect(described_class.count).to eq(1)
      expect(reused.reload).to have_attributes(name: "VIP Order", color: "sky")
    end

    it "accepts thirty characters and counts codepoints rather than bytes" do
      expect(described_class.find_or_create_normalized(name: "x" * 30).name).to eq("x" * 30)
      expect(described_class.find_or_create_normalized(name: "é" * 30).name).to eq("é" * 30)
    end

    it "accepts any number of words" do
      expect(described_class.find_or_create_normalized(name: "one two three").name).to eq("one two three")
    end

    it "rejects invalid names and colors without creating a record" do
      {
        "x" * 31 => [:name, "is too long (maximum is 30 characters)"],
        " \u00A0 " => [:name, "can't be blank"]
      }.each do |name, (attribute, message)|
        expect { described_class.find_or_create_normalized(name:) }
          .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[attribute]).to eq([message]) }
      end

      expect { described_class.find_or_create_normalized(name: "Rush", color: "orange") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:color]).to eq(["is not included in the list"]) }
      expect(described_class.count).to eq(0)
    end

    it "does not reuse an existing identity when another field is invalid and reports only name and color errors" do
      original = create(:sales_tag, name: "VIP Order", color: "sky")

      expect { described_class.find_or_create_normalized(name: "vip order", color: "orange") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error|
          expect(error.record.errors.attribute_names).to eq([:color])
        }
      expect(described_class.count).to eq(1)
      expect(original.reload).to have_attributes(name: "VIP Order", color: "sky")
    end

    it "returns a validation error when the winning tag disappears after a collision" do
      create(:sales_tag, name: "Rush")
      allow(described_class).to receive(:find_by).and_return(nil)

      expect { described_class.find_or_create_normalized(name: "rush") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[:name]).to eq(["changed while saving. Try again."]) }
    end
  end

  describe "#revise" do
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }
    let(:sale) { create(:sale) }

    before { [vip, rush].each { |tag| SaleTagging.create!(sale:, sales_tag: tag) } }

    it "rejects a rename onto another tag's identity as a name error, merging nothing" do
      expect { rush.revise(name: " vip   order ") }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors.to_hash).to eq(name: ["has already been taken"]) }

      expect(rush.reload).to have_attributes(name: "Rush", color: "pink")
      expect(vip.reload).to have_attributes(name: "VIP Order", color: "sky")
      expect(SaleTagging.where(sale:).pluck(:sales_tag_id)).to contain_exactly(vip.id, rush.id)
    end

    it "renames in place, normalizing the name and keeping the identity and assignments" do
      vip.revise(name: "  VIP \u00A0 Client ")

      expect(vip.reload).to have_attributes(name: "VIP Client", normalized_name: "vip client", color: "sky")
      expect(SaleTagging.where(sales_tag: vip).pluck(:sale_id)).to eq([sale.id])
    end

    it "lets a tag change the case of its own name" do
      vip.revise(name: "vip order")

      expect(vip.reload.name).to eq("vip order")
    end

    it "recolors without changing the name" do
      vip.revise(color: "olive")

      expect(vip.reload).to have_attributes(name: "VIP Order", color: "olive")
    end

    it "rejects an unknown color, a blank name and an overlong name without saving" do
      {{color: "orange"} => [:color, "is not included in the list"],
       {name: " \u00A0 "} => [:name, "can't be blank"],
       {name: "x" * 31} => [:name, "is too long (maximum is 30 characters)"]}.each do |attributes, (attribute, message)|
        expect { vip.revise(attributes) }
          .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record.errors[attribute]).to eq([message]) }
        expect(vip.reload).to have_attributes(name: "VIP Order", color: "sky")
      end
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

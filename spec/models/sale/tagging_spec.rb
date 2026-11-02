# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Tagging do
  include ActiveJob::TestHelper

  let(:sale) { create(:sale) }
  let!(:first) { create(:sales_tag, name: "First") }
  let!(:second) { create(:sales_tag, name: "Second") }
  let!(:third) { create(:sales_tag, name: "Third") }

  def assign(*tags)
    tags.each { |tag| SaleTagging.create!(sale:, sales_tag: tag) }
  end

  def assigned_ids
    sale.sale_taggings.reload.pluck(:sales_tag_id).sort
  end

  def tags_error
    sale.errors[:tags].to_sentence
  end

  describe "#replace_tags!" do
    it "replaces the assignments with the requested set, comparing originals as a set" do
      assign(first, second)

      sale.replace_tags!(ids: [second.id], original_ids: [second.id, first.id, first.id])

      expect(assigned_ids).to eq([second.id])
    end

    it "assigns a duplicated requested ID once" do
      sale.replace_tags!(ids: [first.id, first.id, second.id.to_s], original_ids: [])

      expect(assigned_ids).to eq([first.id, second.id])
    end

    it "clears all assignments" do
      assign(first)

      sale.replace_tags!(ids: [], original_ids: [first.id])

      expect(assigned_ids).to eq([])
    end

    it "keeps tags that stay selected untouched" do
      assign(first, second)
      kept_id = sale.sale_taggings.find_by(sales_tag: first).id

      sale.replace_tags!(ids: [first.id, third.id], original_ids: [first.id, second.id])

      expect(sale.sale_taggings.find_by(sales_tag: first).id).to eq(kept_id)
      expect(assigned_ids).to eq([first.id, third.id])
    end

    it "fails with the stale message and changes nothing when the originals differ from the current set" do
      assign(first, second)

      expect { sale.replace_tags!(ids: [third.id], original_ids: [first.id]) }
        .to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.record).to eq(sale) }

      expect(tags_error).to eq("Tags changed since you opened this editor. Reload tags and try again.")
      expect(assigned_ids).to eq([first.id, second.id].sort)
    end

    it "treats missing originals as empty and fails when the sale is already tagged" do
      assign(first)

      expect { sale.replace_tags!(ids: [], original_ids: nil) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(tags_error).to include("Tags changed since you opened this editor")
      expect(assigned_ids).to eq([first.id])
    end

    it "reports a deleted original as stale" do
      assign(first)
      first.destroy

      expect { sale.replace_tags!(ids: [], original_ids: [first.id]) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(tags_error).to include("Tags changed since you opened this editor")
    end

    it "reports a requested deleted ID as missing when nothing else changed" do
      first.destroy

      expect { sale.replace_tags!(ids: [first.id], original_ids: []) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(tags_error).to eq("A selected tag is no longer available. Reload tags and try again.")
      expect(assigned_ids).to eq([])
    end

    it "applies nothing when a valid ID is mixed with an unknown one" do
      assign(first)

      expect { sale.replace_tags!(ids: [second.id, SalesTag.maximum(:id) + 1], original_ids: [first.id]) }
        .to raise_error(ActiveRecord::RecordInvalid)

      expect(tags_error).to include("A selected tag is no longer available")
      expect(assigned_ids).to eq([first.id])
    end

    it "rejects malformed IDs instead of converting them to zero" do
      assign(first)

      [["abc"], ["1.5"], [-1], [0], [nil], [[1]], "1"].each do |bad|
        sale.errors.clear
        expect { sale.replace_tags!(ids: bad, original_ids: [first.id]) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(tags_error).to be_present
      end

      expect(assigned_ids).to eq([first.id])
    end

    describe "proposed tags" do
      let(:rush) { {name: "Rush", color: "sky"} }

      it "creates the proposal and assigns it together with the selected existing tags" do
        sale.replace_tags!(ids: [first.id], original_ids: [], new_tags: [rush])

        created = SalesTag.find_by!(normalized_name: "rush")
        expect(created).to have_attributes(name: "Rush", color: "sky")
        expect(assigned_ids).to eq([first.id, created.id].sort)
      end

      it "reuses an existing identity with its original spelling and color" do
        vip_order = create(:sales_tag, name: "VIP Order", color: "sky")

        sale.replace_tags!(ids: [], original_ids: [], new_tags: [{name: " vip order ", color: "pink"}])

        expect(assigned_ids).to eq([vip_order.id])
        expect(SalesTag.where(normalized_name: "vip order").count).to eq(1)
        expect(vip_order.reload).to have_attributes(name: "VIP Order", color: "sky")
      end

      it "turns duplicate proposals and an already selected match into one identity and one assignment" do
        sale.replace_tags!(
          ids: [first.id],
          original_ids: [],
          new_tags: [rush, {name: " rush ", color: "pink"}, {name: "FIRST", color: "green"}]
        )

        created = SalesTag.where(normalized_name: "rush")
        expect(created.pluck(:name, :color)).to eq([%w[Rush sky]])
        expect(assigned_ids).to eq([first.id, created.first.id].sort)
        expect(SalesTag.where(normalized_name: "first").count).to eq(1)
      end

      it "fails as stale before creating anything when the originals differ from the current set" do
        assign(first, second)

        expect {
          sale.replace_tags!(ids: [first.id], original_ids: [first.id], new_tags: [rush])
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(tags_error).to eq(Sale::Tagging::STALE_ASSIGNMENT_MESSAGE)
        expect(SalesTag.exists?(normalized_name: "rush")).to be(false)
        expect(assigned_ids).to eq([first.id, second.id])
      end

      it "does not apply an already successful request a second time" do
        sale.replace_tags!(ids: [], original_ids: [], new_tags: [rush])
        created = SalesTag.find_by!(normalized_name: "rush")
        SaleTagging.where(sale:).delete_all
        assign(first)

        expect { sale.replace_tags!(ids: [], original_ids: [], new_tags: [rush]) }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(tags_error).to eq(Sale::Tagging::STALE_ASSIGNMENT_MESSAGE)
        expect(assigned_ids).to eq([first.id])
        expect(SalesTag.where(id: created.id).count).to eq(1)
      end

      it "persists neither a valid proposal nor the assignment when another proposal is invalid" do
        expect {
          sale.replace_tags!(ids: [first.id], original_ids: [], new_tags: [rush, {name: "x" * 31, color: "sky"}])
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(tags_error).to include("too long")
        expect(SalesTag.exists?(normalized_name: "rush")).to be(false)
        expect(assigned_ids).to eq([])
      end

      it "reports an invalid color through the tags error and changes nothing" do
        assign(first)

        expect {
          sale.replace_tags!(ids: [], original_ids: [first.id], new_tags: [{name: "Rush", color: "orange"}])
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(tags_error).to include("Color")
        expect(SalesTag.exists?(normalized_name: "rush")).to be(false)
        expect(assigned_ids).to eq([first.id])
      end

      it "rolls back every proposal when a selected tag disappears during the replacement" do
        assign(first)
        allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
          second.delete
          original.call(*args, **kwargs)
        end

        expect {
          sale.replace_tags!(ids: [second.id], original_ids: [first.id], new_tags: [rush])
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(tags_error).to include("A selected tag is no longer available")
        expect(SalesTag.exists?(normalized_name: "rush")).to be(false)
        expect(assigned_ids).to eq([first.id])
      end

      it "rejects unreadable proposals before changing anything" do
        assign(first)

        [[["Rush"]], "Rush", [nil], [{name: ["Rush"], color: "sky"}], [{name: "Rush", color: 1}]].each do |bad|
          sale.errors.clear
          expect { sale.replace_tags!(ids: [], original_ids: [first.id], new_tags: bad) }
            .to raise_error(ActiveRecord::RecordInvalid)
          expect(tags_error).to eq(Sale::Tagging::UNREADABLE_INPUT_MESSAGE)
        end

        expect(SalesTag.exists?(normalized_name: "rush")).to be(false)
        expect(assigned_ids).to eq([first.id])
      end
    end

    it "does not save, touch or announce the sale" do
      assign(first)
      sale.update_columns(updated_at: 1.day.ago)
      stamp = sale.reload.updated_at
      clear_enqueued_jobs
      audits_before = Audited::Audit.count

      expect { sale.replace_tags!(ids: [second.id], original_ids: [first.id]) }
        .not_to have_enqueued_job

      expect(sale.reload.updated_at).to eq(stamp)
      expect(Audited::Audit.count).to eq(audits_before)
    end

    it "turns a tag deleted after validation into the missing-selection error and keeps the old set" do
      assign(first)
      allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
        second.delete
        original.call(*args, **kwargs)
      end

      expect { sale.replace_tags!(ids: [second.id], original_ids: [first.id]) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(tags_error).to include("A selected tag is no longer available")
      expect(assigned_ids).to eq([first.id])
    end
  end

  describe "deletion cascades" do
    it "removes only the assignments when the sale is destroyed" do
      assign(first)

      sale.destroy!

      expect(SaleTagging.count).to eq(0)
      expect(SalesTag.count).to eq(3)
    end

    it "removes only the assignments when a tag is deleted" do
      assign(first)

      first.destroy!

      expect(SaleTagging.count).to eq(0)
      expect(Sale.exists?(sale.id)).to be(true)
    end
  end
end

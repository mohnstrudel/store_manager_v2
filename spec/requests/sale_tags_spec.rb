# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sale tags" do
  let(:sale) { create(:sale) }
  let!(:vip) { create(:sales_tag, name: "VIP") }
  let!(:rush) { create(:sales_tag, name: "Rush") }

  def tagging(**overrides)
    {submitted: "1", **overrides}
  end

  def patch_tags(target = sale, tagging: self.tagging, **extra)
    patch sale_tagging_path(target), params: {sale: {tagging:}, **extra}
  end

  def assigned_ids
    SaleTagging.where(sale:).pluck(:sales_tag_id).sort
  end

  def errors_after_redirect
    follow_redirect!
    inertia.props[:errors].deep_symbolize_keys
  end

  describe "PATCH /sales/:sale_id/tags" do
    before { sign_in_as_admin }

    it "replaces assignments and redirects 303 to the sale with a notice" do
      SaleTagging.create!(sale:, sales_tag: vip)

      patch_tags(tagging: tagging(ids: [rush.id], original_ids: [vip.id]))

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(sale_path(sale))
      expect(flash[:notice]).to eq("Tags saved")
      expect(assigned_ids).to eq([rush.id])
    end

    it "accepts HTML digit strings and the friendly slug" do
      patch sale_tagging_path(sale.slug), params: {sale: {tagging: {submitted: "1", ids: [vip.id.to_s]}}}

      expect(response).to have_http_status(:see_other)
      expect(assigned_ids).to eq([vip.id])
    end

    it "clears all assignments when ids are omitted but originals are sent" do
      SaleTagging.create!(sale:, sales_tag: vip)

      patch sale_tagging_path(sale), params: {sale: {tagging: {submitted: "1", original_ids: [vip.id]}}}

      expect(assigned_ids).to eq([])
    end

    it "accepts a JSON body with empty arrays as the Inertia client sends it" do
      SaleTagging.create!(sale:, sales_tag: vip)

      patch sale_tagging_path(sale), params: {sale: {tagging: {submitted: "1", ids: [], original_ids: [vip.id]}}}, as: :json

      expect(response).to have_http_status(:see_other)
      expect(assigned_ids).to eq([])

      patch sale_tagging_path(sale), params: {sale: {tagging: {submitted: "1", ids: [vip.id], original_ids: []}}}, as: :json

      expect(assigned_ids).to eq([vip.id])
    end

    it "assigns a duplicated ID once" do
      patch_tags(tagging: tagging(ids: [vip.id, vip.id]))

      expect(assigned_ids).to eq([vip.id])
    end

    it "ignores unrelated sale attributes" do
      patch sale_tagging_path(sale), params: {
        sale: {status: "cancelled", note: "hacked", tagging: tagging(ids: [vip.id])}
      }

      expect(assigned_ids).to eq([vip.id])
      expect(sale.reload).to have_attributes(status: "processing", note: "")
    end

    it "does not touch the sale" do
      sale.update_columns(updated_at: 1.day.ago)
      stamp = sale.reload.updated_at

      patch_tags(tagging: tagging(ids: [vip.id]))

      expect(sale.reload.updated_at).to eq(stamp)
    end

    it "reports a missing submitted marker as a tags error and changes nothing" do
      SaleTagging.create!(sale:, sales_tag: vip)

      patch sale_tagging_path(sale), params: {sale: {tagging: {ids: [rush.id], original_ids: [vip.id]}}}

      expect(response).to have_http_status(:see_other)
      expect(errors_after_redirect).to include(:tags)
      expect(assigned_ids).to eq([vip.id])
    end

    it "reports a missing tagging object as a tags error" do
      patch sale_tagging_path(sale), params: {sale: {note: "x"}}

      expect(response).to have_http_status(:see_other)
      expect(errors_after_redirect).to include(:tags)
    end

    it "rejects new tags and creates nothing" do
      expect {
        patch_tags(tagging: tagging(ids: [vip.id], new_tags: [{name: "Fresh", color: "blue"}]))
      }.not_to change(SalesTag, :count)

      expect(response).to have_http_status(:see_other)
      expect(errors_after_redirect).to include(:tags)
      expect(assigned_ids).to eq([])
    end

    it "reports a stale original set with the exact message" do
      SaleTagging.create!(sale:, sales_tag: vip)

      patch_tags(tagging: tagging(ids: [rush.id]))

      expect(errors_after_redirect).to eq(tags: "Tags changed since you opened this editor. Reload tags and try again.")
      expect(assigned_ids).to eq([vip.id])
    end

    it "reports a deleted selection with the exact message" do
      deleted_id = rush.id
      rush.destroy

      patch_tags(tagging: tagging(ids: [vip.id, deleted_id]))

      expect(errors_after_redirect).to eq(tags: "A selected tag is no longer available. Reload tags and try again.")
      expect(assigned_ids).to eq([])
    end

    it "rejects malformed IDs" do
      patch_tags(tagging: tagging(ids: ["abc"]))

      expect(errors_after_redirect).to include(:tags)
      expect(assigned_ids).to eq([])
    end

    [
      ["ids as a hash", :ids, {bad: "value"}],
      ["ids as a scalar", :ids, "1"],
      ["ids containing a hash", :ids, [{bad: "value"}]],
      ["original_ids as a hash", :original_ids, {bad: "value"}],
      ["original_ids as a scalar", :original_ids, "1"]
    ].each do |label, field, malformed|
      it "keeps existing assignments and reports an error for #{label}" do
        SaleTagging.create!(sale:, sales_tag: vip)

        patch_tags(tagging: tagging(ids: [rush.id], original_ids: [vip.id], **{field => malformed}))

        expect(response).to have_http_status(:see_other)
        expect(errors_after_redirect).to include(:tags)
        expect(assigned_ids).to eq([vip.id])
      end
    end

    it "returns 404 for a sale that does not exist" do
      patch sale_tagging_path("missing"), params: {sale: {tagging:}}

      expect(response).to have_http_status(:not_found)
    end

    describe "return_to" do
      it "redirects to a local sales listing path with its query" do
        patch_tags(return_to: "/sales?q=batch&sort=oldest")

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to("/sales?q=batch&sort=oldest")
      end

      it "returns validation errors to the same local path" do
        patch_tags(tagging: tagging(ids: ["abc"]), return_to: "/sales?page=2")

        expect(response).to redirect_to("/sales?page=2")
        expect(errors_after_redirect).to include(:tags)
      end

      it "accepts another sale path" do
        patch_tags(return_to: "/sales/#{sale.id}")

        expect(response).to redirect_to("/sales/#{sale.id}")
      end

      [
        "https://evil.example/sales", "//evil.example/sales", "/\\evil.example", "/sales\\x", "/sales//evil",
        "/purchases", "/salesx", "/sales/../purchases", "/sales/%2e%2e/purchases", "/sales#frag", "sales", "javascript:alert(1)", ""
      ].each do |unsafe|
        it "falls back to the sale for #{unsafe.inspect}" do
          patch_tags(return_to: unsafe)

          expect(response).to redirect_to(sale_path(sale))
        end
      end
    end
  end

  describe "role access" do
    %i[admin manager support].each do |role|
      it "lets #{role} users assign tags" do
        sign_in create(:user, role:)

        patch_tags(tagging: tagging(ids: [vip.id]))

        expect(response).to have_http_status(:see_other)
        expect(assigned_ids).to eq([vip.id])
      end
    end

    it "keeps guests from changing tags" do
      sign_in create(:user, role: :guest)

      patch_tags(tagging: tagging(ids: [vip.id]))

      expect(response).to redirect_to(noop_path)
      expect(assigned_ids).to eq([])
    end
  end
end

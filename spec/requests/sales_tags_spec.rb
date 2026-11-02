# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SalesTags" do
  describe "GET /sales_tags" do
    before { sign_in_as_admin }

    it "renders alphabetical catalog tags with zero usage, the color keys and no open form" do
      zebra = create(:sales_tag, name: "Zebra", color: "pink")
      apple = create(:sales_tag, name: "apple", color: "green")

      get sales_tags_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("SalesTags/Index")
      expect(inertia.props[:sales_tags].map(&:deep_symbolize_keys)).to eq([
        {id: apple.id, name: "apple", color: "green", usage_count: 0},
        {id: zebra.id, name: "Zebra", color: "pink", usage_count: 0}
      ])
      expect(inertia.props[:tag_colors]).to eq(%w[green pink sky violet olive])
      expect(inertia.props[:sales_tag]).to be_nil
      expect(inertia.props).not_to have_key(:search)
    end

    it "counts every assigned sale once per tag regardless of sale status" do
      vip = create(:sales_tag, name: "VIP")
      unused = create(:sales_tag, name: "Unused")
      %w[processing completed cancelled].each do |status|
        SaleTagging.create!(sale: create(:sale, status:), sales_tag: vip)
      end

      get sales_tags_path

      expect(inertia.props[:sales_tags].to_h { |tag| [tag[:id], tag[:usage_count]] }).to eq(vip.id => 3, unused.id => 0)
    end
  end

  describe "GET /sales_tags/new" do
    before { sign_in_as_admin }

    it "renders the list with a blank green draft open" do
      existing = create(:sales_tag, name: "VIP")

      get new_sales_tag_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("SalesTags/Index")
      expect(inertia.props[:sales_tag].deep_symbolize_keys).to eq(id: nil, name: "", color: "green")
      expect(inertia.props[:sales_tags].pluck(:id)).to eq([existing.id])
    end
  end

  describe "GET /sales_tags/:id/edit" do
    before { sign_in_as_admin }

    it "renders the list with the saved tag open" do
      vip = create(:sales_tag, name: "VIP Order", color: "sky")
      create(:sales_tag, name: "Rush")

      get edit_sales_tag_path(vip)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("SalesTags/Index")
      expect(inertia.props[:sales_tag].deep_symbolize_keys).to eq(id: vip.id, name: "VIP Order", color: "sky")
      expect(inertia.props[:sales_tags].size).to eq(2)
    end
  end

  describe "GET /sales_tags/:id" do
    before { sign_in_as_admin }

    it "renders the list with the tag and a labelled link with item images for each of its sales, newest first" do
      vip = create(:sales_tag, name: "VIP Order", color: "sky")
      older = create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 1))
      newer = create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 2), status: "completed")
      untagged = create(:sale, shopify_name: "HSCM#1003")
      create(:sale_item, sale: untagged)
      older_item = create(:sale_item, sale: older, variant: nil)
      product = create(:product)
      create(:media, :for_product, mediaable: product)
      newer_item = create(:sale_item, sale: newer, product:, variant: create(:variant, product:))
      [older, newer].each { |sale| SaleTagging.create!(sale:, sales_tag: vip) }

      get sales_tag_path(vip)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("SalesTags/Index")
      detail = inertia.props[:sales_tag_detail].deep_symbolize_keys
      expect(detail).to include(id: vip.id, name: "VIP Order", color: "sky")
      expect(detail[:sales].map { |sale| sale.slice(:id, :path, :label) }).to eq([
        {id: newer.id, path: sale_path(newer), label: "HSCM#1002, Michele Pomarico, italy_mp@web.de, #{newer_item.title}"},
        {id: older.id, path: sale_path(older), label: "HSCM#1001, Michele Pomarico, italy_mp@web.de, #{older_item.title}"}
      ])
      newer_items, older_items = detail[:sales].pluck(:items)
      expect(newer_items.map { |item| item.slice(:id, :title) }).to eq([{id: newer_item.id, title: newer_item.title}])
      expect(newer_items.sole[:product_thumb_url]).to be_present
      expect(older_items).to eq([{id: older_item.id, title: older_item.title, product_thumb_url: nil}])
      expect(inertia.props[:sales_tag]).to be_nil
    end

    it "lists no sales for an unused tag" do
      unused = create(:sales_tag, name: "Unused")

      get sales_tag_path(unused)

      expect(inertia.props[:sales_tag_detail].deep_symbolize_keys).to eq(id: unused.id, name: "Unused", color: "green", sales: [])
    end
  end

  describe "POST /sales_tags" do
    before { sign_in_as_admin }

    it "creates a tag and redirects with 303 to the catalog" do
      expect {
        post sales_tags_path, params: {sales_tag: {name: "  VIP   Order ", color: "sky"}}
      }.to change(SalesTag, :count).by(1)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(sales_tags_path)
      expect(flash[:notice]).to eq("Sales tag saved")
      expect(SalesTag.last).to have_attributes(name: "VIP Order", color: "sky")
    end

    it "reuses an existing identity and preserves its name and color" do
      existing = create(:sales_tag, name: "VIP Order", color: "sky")

      expect {
        post sales_tags_path, params: {sales_tag: {name: " vip   order ", color: "pink"}}
      }.not_to change(SalesTag, :count)

      expect(response).to redirect_to(sales_tags_path)
      expect(existing.reload).to have_attributes(name: "VIP Order", color: "sky")
    end

    it "defaults the color to green" do
      post sales_tags_path, params: {sales_tag: {name: "Rush"}}

      expect(SalesTag.last).to have_attributes(name: "Rush", color: "green")
    end

    it "redirects with 303 back to the new form with name and color errors for invalid input" do
      expect {
        post sales_tags_path, params: {sales_tag: {name: "x" * 31, color: "orange"}}
      }.not_to change(SalesTag, :count)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(new_sales_tag_path)
      follow_redirect!
      expect(inertia.props[:errors].deep_symbolize_keys).to eq(
        name: "is too long (maximum is 30 characters)",
        color: "is not included in the list"
      )
    end

    it "reports a blank name" do
      post sales_tags_path, params: {sales_tag: {name: "  ", color: "sky"}}
      follow_redirect!

      expect(inertia.props[:errors]).to include(name: "can't be blank")
    end

    it "reports a missing name field instead of failing" do
      expect {
        post sales_tags_path, params: {sales_tag: {color: "sky"}}
      }.not_to change(SalesTag, :count)

      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(inertia.props[:errors]).to include(name: "can't be blank")
    end

    it "does not reuse an existing identity when the color is invalid" do
      existing = create(:sales_tag, name: "VIP Order", color: "sky")

      expect {
        post sales_tags_path, params: {sales_tag: {name: "vip order", color: "orange"}}
      }.not_to change(SalesTag, :count)

      follow_redirect!
      expect(inertia.props[:errors].deep_symbolize_keys).to eq(color: "is not included in the list")
      expect(existing.reload).to have_attributes(name: "VIP Order", color: "sky")
    end
  end

  describe "PATCH /sales_tags/:id" do
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    before { sign_in_as_admin }

    it "renames and recolors in place, redirecting 303 to the catalog" do
      sale = create(:sale)
      SaleTagging.create!(sale:, sales_tag: vip)

      patch sales_tag_path(vip), params: {sales_tag: {name: " VIP   Client ", color: "olive"}}

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(sales_tags_path)
      expect(flash[:notice]).to eq("Sales tag saved")
      expect(vip.reload).to have_attributes(name: "VIP Client", color: "olive")
      expect(sale.sales_tags).to eq([vip])
    end

    it "rejects a rename onto another tag's identity, back to its edit form, without changing either tag" do
      patch sales_tag_path(rush), params: {sales_tag: {name: " vip   order ", color: "violet"}}

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(edit_sales_tag_path(rush))
      follow_redirect!
      expect(inertia.props[:errors].deep_symbolize_keys).to eq(name: "has already been taken")
      expect(rush.reload).to have_attributes(name: "Rush", color: "pink")
      expect(vip.reload).to have_attributes(name: "VIP Order", color: "sky")
    end

    it "redirects with 303 and name and color errors for invalid input" do
      patch sales_tag_path(vip), params: {sales_tag: {name: "x" * 31, color: "orange"}}

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(edit_sales_tag_path(vip))
      follow_redirect!
      expect(inertia.props[:errors].deep_symbolize_keys).to eq(
        name: "is too long (maximum is 30 characters)",
        color: "is not included in the list"
      )
      expect(vip.reload).to have_attributes(name: "VIP Order", color: "sky")
    end
  end

  describe "role access" do
    %i[manager support guest].each do |role|
      it "keeps catalog management away from #{role} users" do
        sign_in create(:user, role:)
        existing = create(:sales_tag, name: "Existing")

        [sales_tags_path, sales_tag_path(existing), new_sales_tag_path, edit_sales_tag_path(existing)].each do |path|
          get path
          expect(response).to redirect_to(noop_path)
        end

        expect {
          post sales_tags_path, params: {sales_tag: {name: "Rush", color: "sky"}}
        }.not_to change(SalesTag, :count)
        expect(response).to redirect_to(noop_path)

        patch sales_tag_path(existing), params: {sales_tag: {name: "Renamed", color: "pink"}}
        expect(response).to redirect_to(noop_path)
        expect(existing.reload).to have_attributes(name: "Existing", color: "green")
      end
    end
  end
end

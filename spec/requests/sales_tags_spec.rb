# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SalesTags" do
  describe "GET /sales_tags" do
    before { sign_in_as_admin }

    it "renders alphabetical catalog tags with zero usage and the color keys" do
      zebra = create(:sales_tag, name: "Zebra", color: "red")
      apple = create(:sales_tag, name: "apple", color: "green")

      get sales_tags_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("SalesTags/Index")
      expect(inertia.props[:sales_tags].map(&:deep_symbolize_keys)).to eq([
        {id: apple.id, name: "apple", color: "green", usage_count: 0},
        {id: zebra.id, name: "Zebra", color: "red", usage_count: 0}
      ])
      expect(inertia.props[:search].deep_symbolize_keys).to eq(q: "")
      expect(inertia.props[:tag_colors]).to eq(%w[red yellow green blue violet fuchsia])
    end

    it "counts every assigned sale once per tag regardless of sale status" do
      vip = create(:sales_tag, name: "VIP")
      unused = create(:sales_tag, name: "Unused")
      %w[processing completed cancelled].each do |status|
        SaleTagging.create!(sale: create(:sale, status:), sales_tag: vip)
      end

      get sales_tags_path(q: "vip")
      expect(inertia.props[:sales_tags].map(&:deep_symbolize_keys)).to eq([{id: vip.id, name: "VIP", color: "yellow", usage_count: 3}])

      get sales_tags_path
      expect(inertia.props[:sales_tags].to_h { |tag| [tag[:id], tag[:usage_count]] }).to eq(vip.id => 3, unused.id => 0)
    end

    it "searches by case-insensitive literal substring" do
      vip = create(:sales_tag, name: "VIP Order")
      create(:sales_tag, name: "Rush")

      get sales_tags_path(q: " vip ")

      expect(inertia.props[:sales_tags].pluck(:id)).to eq([vip.id])
      expect(inertia.props[:search].deep_symbolize_keys).to eq(q: "vip")
    end

    it "treats a percent sign as a literal character, not a wildcard" do
      percent = create(:sales_tag, name: "50%off")
      create(:sales_tag, name: "Rush")

      get sales_tags_path(q: "%")

      expect(inertia.props[:sales_tags].pluck(:id)).to eq([percent.id])
    end
  end

  describe "POST /sales_tags" do
    before { sign_in_as_admin }

    it "creates a tag and redirects with 303 to the catalog, keeping the management search" do
      expect {
        post sales_tags_path(q: "vip"), params: {sales_tag: {name: "  VIP   Order ", color: "blue"}}
      }.to change(SalesTag, :count).by(1)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(sales_tags_path(q: "vip"))
      expect(SalesTag.last).to have_attributes(name: "VIP Order", color: "blue")
    end

    it "reuses an existing identity and preserves its name and color" do
      existing = create(:sales_tag, name: "VIP Order", color: "blue")

      expect {
        post sales_tags_path, params: {sales_tag: {name: " vip   order ", color: "red"}}
      }.not_to change(SalesTag, :count)

      expect(response).to redirect_to(sales_tags_path)
      expect(existing.reload).to have_attributes(name: "VIP Order", color: "blue")
    end

    it "defaults the color to yellow" do
      post sales_tags_path, params: {sales_tag: {name: "Rush"}}

      expect(SalesTag.last).to have_attributes(name: "Rush", color: "yellow")
    end

    it "redirects with 303 and name and color errors for invalid input" do
      expect {
        post sales_tags_path(q: "ru"), params: {sales_tag: {name: "one two three", color: "pink"}}
      }.not_to change(SalesTag, :count)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(sales_tags_path(q: "ru"))
      follow_redirect!
      expect(inertia.props[:errors].deep_symbolize_keys).to eq(
        name: "must be one or two words",
        color: "is not included in the list"
      )
    end

    it "reports a blank name" do
      post sales_tags_path, params: {sales_tag: {name: "  ", color: "blue"}}
      follow_redirect!

      expect(inertia.props[:errors]).to include(name: "can't be blank")
    end

    it "reports a missing name field instead of failing" do
      expect {
        post sales_tags_path, params: {sales_tag: {color: "blue"}}
      }.not_to change(SalesTag, :count)

      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(inertia.props[:errors]).to include(name: "can't be blank")
    end

    it "does not reuse an existing identity when the color is invalid" do
      existing = create(:sales_tag, name: "VIP Order", color: "blue")

      expect {
        post sales_tags_path, params: {sales_tag: {name: "vip order", color: "pink"}}
      }.not_to change(SalesTag, :count)

      follow_redirect!
      expect(inertia.props[:errors].deep_symbolize_keys).to eq(color: "is not included in the list")
      expect(existing.reload).to have_attributes(name: "VIP Order", color: "blue")
    end
  end

  describe "role access" do
    %i[manager support guest].each do |role|
      it "keeps catalog management away from #{role} users" do
        sign_in create(:user, role:)
        create(:sales_tag, name: "Existing")

        get sales_tags_path
        expect(response).to redirect_to(noop_path)

        expect {
          post sales_tags_path, params: {sales_tag: {name: "Rush", color: "blue"}}
        }.not_to change(SalesTag, :count)
        expect(response).to redirect_to(noop_path)
      end
    end
  end
end

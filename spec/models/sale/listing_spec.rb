# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Listing do
  describe ".listing_sort" do
    it "keeps known sorts and falls back to newest" do
      expect([nil, "", "oldest", "newest", "id", ["oldest"]].map { |value| Sale.listing_sort(value) })
        .to eq(%w[newest newest oldest newest newest newest])
    end
  end

  describe ".listing sorting" do
    def listed_ids(sort:, query: "")
      Sale.listing(query:, sort:).map(&:id)
    end

    def create_sale_at(shopify: nil, woo: nil, created: Time.utc(2024, 1, 1), **attributes)
      create(:sale, shopify_created_at: shopify, woo_created_at: woo, created_at: created, **attributes)
    end

    it "orders by Shopify, then Woo, then local creation time" do
      a = create_sale_at(shopify: Time.utc(2024, 1, 3), woo: Time.utc(2024, 1, 1), created: Time.utc(2024, 2, 1))
      b = create_sale_at(woo: Time.utc(2024, 1, 2), created: Time.utc(2024, 2, 1))
      c = create_sale_at(created: Time.utc(2024, 1, 1))

      expect(listed_ids(sort: "oldest")).to eq([c.id, b.id, a.id])
      expect(listed_ids(sort: "newest")).to eq([a.id, b.id, c.id])
    end

    it "breaks ties by sale ID in the selected direction" do
      moment = Time.utc(2024, 1, 1)
      first = create_sale_at(woo: moment)
      second = create_sale_at(woo: moment)

      expect(listed_ids(sort: "oldest")).to eq([first.id, second.id])
      expect(listed_ids(sort: "newest")).to eq([second.id, first.id])
    end

    it "lets the selected date order override search relevance" do
      older_weaker = create_sale_at(woo: Time.utc(2024, 1, 1), note: "pikachu among many other unrelated words here")
      newer_stronger = create_sale_at(woo: Time.utc(2024, 1, 2), shopify_name: "pikachu", note: "pikachu")

      expect(Sale.search("pikachu").map(&:id)).to eq([newer_stronger.id, older_weaker.id])
      expect(listed_ids(sort: "oldest", query: "pikachu")).to eq([older_weaker.id, newer_stronger.id])
      expect(listed_ids(sort: "newest", query: "pikachu")).to eq([newer_stronger.id, older_weaker.id])
    end

    it "excludes completed and cancelled sales" do
      open_sale = create_sale_at(status: "processing")
      create_sale_at(status: "completed")
      create_sale_at(status: "cancelled")

      expect(listed_ids(sort: "oldest")).to eq([open_sale.id])
    end
  end

  describe ".listing with hide_partial_payments" do
    def listed_ids(query: "", sort: "newest", hide_partial_payments: true)
      Sale.listing(query:, sort:, hide_partial_payments:).map(&:id)
    end

    def link_follow_up(origin_order_id:, follow_up_order_id:)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-#{origin_order_id}",
          external_origin_order_id: origin_order_id,
          kind: "installments",
          status: "active",
          expected_parts: 2,
          synced_at: Time.current
        },
        parts: [
          {provider_part_id: "#{origin_order_id}-1", sequence: 1, external_order_id: origin_order_id},
          {provider_part_id: "#{origin_order_id}-2", sequence: 2, external_order_id: follow_up_order_id}
        ]
      )
    end

    it "drops follow-up payments, keeps origins and ordinary sales, and totals only the matches" do
      origin = create(:sale, woo_created_at: Time.utc(2024, 1, 1), shopify_store_id: "gid://shopify/Order/900")
      create(:sale, woo_created_at: Time.utc(2024, 1, 2), shopify_store_id: "gid://shopify/Order/901")
      ordinary = create(:sale, woo_created_at: Time.utc(2024, 1, 3))
      link_follow_up(origin_order_id: "900", follow_up_order_id: "901")

      listing = Sale.listing(query: "", sort: "oldest", hide_partial_payments: true)

      expect(listing.map(&:id)).to eq([origin.id, ordinary.id])
      expect(listing.page(1).total_count).to eq(2)
      expect(Sale.listing(query: "", sort: "oldest", hide_partial_payments: false).count).to eq(3)
    end

    it "searches before filtering, so a filtered-out exact Store ID does not fall back to full text" do
      create(:sale, shopify_store_id: "gid://shopify/Order/900")
      create(:sale, shopify_store_id: "gid://shopify/Order/901")
      create(:sale, note: "customer asked about 901")
      link_follow_up(origin_order_id: "900", follow_up_order_id: "901")

      expect(listed_ids(query: "901", hide_partial_payments: true)).to be_empty
      expect(listed_ids(query: "901", hide_partial_payments: false).size).to eq(1)
    end
  end
end

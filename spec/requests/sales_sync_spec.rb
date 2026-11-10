# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales Sync API" do
  before { sign_in_as_admin }

  describe "POST /sales/pull" do
    it "enqueues a full Shopify pull and a delayed Woo pull with no limit, without enqueuing Seal directly", :aggregate_failures do
      freeze_time do
        post sales_bulk_pull_path

        expect(Shopify::PullSalesJob).to have_been_enqueued.with(changes_only: false, requested_by: admin)
        expect(Woo::PullSalesJob).to have_been_enqueued.with(limit: nil, requested_by: admin).at(90.seconds.from_now)
        expect(Seal::SyncPaymentPlansJob).not_to have_been_enqueued
      end
    end

    it "enqueues a Shopify changes pull and a delayed Woo pull of the latest 100 for scope=changes", :aggregate_failures do
      freeze_time do
        post sales_bulk_pull_path(scope: "changes")

        expect(Shopify::PullSalesJob).to have_been_enqueued.with(changes_only: true, requested_by: admin)
        expect(Woo::PullSalesJob).to have_been_enqueued.with(limit: 100, requested_by: admin).at(90.seconds.from_now)
        expect(Seal::SyncPaymentPlansJob).not_to have_been_enqueued
      end
    end

    it "pulls everything when only the retired limit param is sent", :aggregate_failures do
      post sales_bulk_pull_path(limit: "100")

      expect(Shopify::PullSalesJob).to have_been_enqueued.with(changes_only: false, requested_by: admin)
      expect(Woo::PullSalesJob).to have_been_enqueued.with(limit: nil, requested_by: admin)
    end

    it "leaves the stored sync time to the pull itself" do
      Config.update_shopify_sales_sync_time(Time.utc(2026, 11, 10, 10))

      expect { post sales_bulk_pull_path(scope: "changes") }.not_to change(Config, :shopify_sales_sync_at)
    end

    it "redirects back with a jobs dashboard notice", :aggregate_failures do
      post sales_bulk_pull_path

      expect(response).to redirect_to(sales_path)
      expect(flash[:notice]).to include(message: start_with("Started. You'll get a notification"))
      expect(flash[:notice]).to include(link: hash_including(label: "jobs dashboard"))
    end
  end
end

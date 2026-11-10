# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BrokenSales::Backfills API" do
  describe "POST /broken_sales/backfill" do
    context "when signed in as admin" do
      before { sign_in_as_admin }

      it "enqueues the backfill job and redirects with a jobs status notice", :aggregate_failures do
        allow(Variant::AssignmentBackfillJob).to receive(:perform_later)

        post broken_sales_backfill_path

        expect(Variant::AssignmentBackfillJob).to have_received(:perform_later).with(requested_by: admin)
        expect(response).to redirect_to(broken_sales_path)
        expect(flash[:notice]).to include(message: start_with("Started. You'll get a notification"))
      end
    end

    context "when signed in as a non-admin user" do
      before { sign_in(create(:user)) }

      it "does not enqueue the backfill job and redirects with an error", :aggregate_failures do
        allow(Variant::AssignmentBackfillJob).to receive(:perform_later)

        post broken_sales_backfill_path

        expect(Variant::AssignmentBackfillJob).not_to have_received(:perform_later)
        expect(flash[:alert]).to include("permission")
      end
    end
  end
end

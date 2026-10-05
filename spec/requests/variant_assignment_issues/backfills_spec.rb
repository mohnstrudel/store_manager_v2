# frozen_string_literal: true

require "rails_helper"

RSpec.describe "VariantAssignmentIssues::Backfills API" do
  describe "POST /variant_assignment_issues/backfill" do
    context "when signed in as admin" do
      before { sign_in_as_admin }

      it "enqueues the backfill job and redirects with a jobs status notice", :aggregate_failures do
        allow(Variant::AssignmentBackfillJob).to receive(:perform_later)

        post variant_assignment_issues_backfill_path

        expect(Variant::AssignmentBackfillJob).to have_received(:perform_later)
        expect(response).to redirect_to(variant_assignment_issues_path)
        expect(flash[:notice]).to include(message: "Success! Visit")
      end
    end

    context "when signed in as a non-admin user" do
      before { sign_in(create(:user)) }

      it "does not enqueue the backfill job and redirects with an error", :aggregate_failures do
        allow(Variant::AssignmentBackfillJob).to receive(:perform_later)

        post variant_assignment_issues_backfill_path

        expect(Variant::AssignmentBackfillJob).not_to have_received(:perform_later)
        expect(flash[:error]).to include("permission")
      end
    end
  end
end
